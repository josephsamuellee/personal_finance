class AccountObservation < ApplicationRecord
  include DatedObservation

  belongs_to :account

  validates :amount, presence: true, numericality: true
  validate :debt_amount_is_nonnegative

  private
    def debt_amount_is_nonnegative
      return unless account&.debt?
      return if amount.nil?

      errors.add(:amount, "must be zero or positive") if amount.negative?
    end
end
