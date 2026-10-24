class QuickExpensesController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :resume_session
  layout :page_layout

  def new
    @expense = Expense.new(spent_on: Date.current, kind: "spending")
  end

  def create
    @expense = build_expense
    if entry_acceptable?
      files = uploaded_receipts
      @expense.receipts.attach(files) if files.any?
      if @expense.save
        redirect_to quick_expense_path, notice: "Expense saved. You can enter another."
        return
      end
    end

    render :new, status: :unprocessable_entity
  end

  private
    def page_layout
      authenticated? ? "application" : "quick_expense"
    end

    def entry
      params.fetch(:expense, ActionController::Parameters.new).permit(
        :amount, :category_name, :spent_on, :merchant, :notes, receipts: []
      )
    end

    def build_expense
      expense = Expense.new(
        kind: "spending",
        category_name: entry[:category_name].to_s.strip,
        merchant: entry[:merchant],
        notes: entry[:notes],
        created_by: current_user,
        updated_by: current_user
      )
      expense.amount = entry[:amount] if positive_amount?(entry[:amount])
      expense.spent_on = entry[:spent_on].blank? ? Date.current : parsed_date(entry[:spent_on])
      expense
    end

    def entry_acceptable?
      acceptable = true
      name = @expense.category_name.to_s
      if name.blank? || name.length > 80
        @expense.errors.add(:category_name, "must be present and at most 80 characters")
        acceptable = false
      end
      if @expense.merchant.to_s.length > 120
        @expense.errors.add(:merchant, "must be at most 120 characters")
        acceptable = false
      end
      if @expense.notes.to_s.length > 2000
        @expense.errors.add(:notes, "must be at most 2000 characters")
        acceptable = false
      end
      unless positive_amount?(entry[:amount])
        @expense.errors.add(:amount, "must be a positive number")
        acceptable = false
      end
      raw_date = entry[:spent_on].to_s
      if raw_date.present?
        date = parsed_date(raw_date)
        if date.nil?
          @expense.errors.add(:spent_on, "is invalid")
          acceptable = false
        elsif date < Date.new(2000, 1, 1) || date > Date.new(2100, 12, 31)
          @expense.errors.add(:spent_on, "is out of range")
          acceptable = false
        end
      end
      uploaded_receipts.each do |file|
        next if Expense::RECEIPT_TYPES.include?(file.content_type)

        @expense.errors.add(:receipts, "must be an image or a PDF")
        acceptable = false
      end
      acceptable
    end

    def positive_amount?(value)
      text = value.to_s.strip
      return false unless text.match?(/\A\d+(\.\d{1,2})?\z/)

      !BigDecimal(text).zero?
    end

    def parsed_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def uploaded_receipts
      Array(entry[:receipts]).reject { |file| file.blank? }
    end
end
