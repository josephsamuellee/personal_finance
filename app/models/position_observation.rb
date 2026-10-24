class PositionObservation < ApplicationRecord
  include DatedObservation

  belongs_to :account
  belongs_to :security

  validates :quantity, :cost_basis, presence: true
  validates :quantity, :cost_basis, numericality: { greater_than_or_equal_to: 0 }

  def closed?
    quantity.to_d.zero?
  end
end
