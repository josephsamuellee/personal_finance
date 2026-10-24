class Expense < ApplicationRecord
  include Revisable

  KINDS = %w[spending refund transfer].freeze
  RECEIPT_TYPES = %w[image/jpeg image/png image/gif image/webp application/pdf].freeze

  enum :kind, KINDS.index_with(&:itself), validate: true

  belongs_to :expense_category, optional: true
  belongs_to :refund_of, class_name: "Expense", optional: true
  belongs_to :source_account, class_name: "Account", optional: true
  belongs_to :destination_account, class_name: "Account", optional: true
  belongs_to :import_batch, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many_attached :receipts

  attr_accessor :category_name

  scope :kept, -> { where(discarded_at: nil) }
  scope :tracked, -> { kept.where(kind: %w[spending refund]) }

  validates :amount, :spent_on, presence: true
  validates :amount, numericality: { other_than: 0 }
  validates :expense_category, presence: true, unless: :transfer?
  validates :source_account, :destination_account, presence: true, if: :transfer?
  validate :acceptable_receipts

  before_validation :assign_category_from_name
  before_validation :normalize_amount

  def discard_from_active_use!(user:)
    self.revision_user = user
    self.revision_reason = "removed from active use"
    update!(discarded_at: Time.current, updated_by: user)
  end

  private
    def assign_category_from_name
      return if category_name.blank?

      self.expense_category = ExpenseCategory.find_or_create_by!(name: category_name)
    end

    def normalize_amount
      return if amount.nil?

      self.amount = if refund?
        -amount.abs
      else
        amount.abs
      end
    end

    def acceptable_receipts
      receipts.each do |receipt|
        next if receipt.blob.blank?
        next if RECEIPT_TYPES.include?(receipt.blob.content_type)

        errors.add(:receipts, "must be an image or a PDF")
      end
    end
end
