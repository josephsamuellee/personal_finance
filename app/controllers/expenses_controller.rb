class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[ show edit update ]

  def index
    @month = params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current
    range = @month.all_month
    @expenses = Expense.kept.where(spent_on: range).order(spent_on: :desc, id: :desc)
    @any_expenses = Expense.kept.exists?
    @total = Reporting::Spending.total(range)
    @categories = Reporting::Spending.by_category(range)
    @baseline = Reporting::Spending.baseline(@month.end_of_month)
  rescue ActiveRecord::StatementInvalid
    @load_error = true
    @month ||= Date.current
    @expenses = []
    @any_expenses = false
    @categories = {}
    @total = nil
    @baseline = { average: nil, months: [], totals: [] }
  end

  def show
  end

  def new
    @expense = Expense.new(spent_on: Date.current, kind: "spending", amount: params.dig(:expense, :amount))
  end

  def create
    @expense = Expense.new(expense_params)
    @expense.created_by = current_user
    @expense.updated_by = current_user
    @expense.revision_user = current_user
    if @expense.save
      redirect_to new_expense_path, notice: "Expense saved. You can enter another."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def destroy
    head :not_found
  end

  def update
    @expense.revision_user = current_user
    @expense.updated_by = current_user
    if @expense.update(expense_params)
      redirect_to @expense, notice: "Expense updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_expense
      @expense = Expense.find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(
        :kind, :amount, :spent_on, :expense_category_id, :category_name, :merchant, :notes,
        :refund_of_id, :source_account_id, :destination_account_id, receipts: []
      )
    end
end
