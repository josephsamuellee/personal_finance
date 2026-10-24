class ExpenseCategory < ApplicationRecord
  has_many :expenses, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  normalizes :name, with: ->(value) { value.to_s.strip }
end
