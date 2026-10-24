class MarketPrice < ApplicationRecord
  belongs_to :security
  belongs_to :entered_by, class_name: "User", optional: true

  validates :amount, :market_on, :retrieved_at, :source, :currency, presence: true
  validates :amount, numericality: { greater_than: 0 }

  def self.usable_on(security, date)
    where(security: security, market_on: ..date).order(market_on: :desc, retrieved_at: :desc).first
  end

  def manual?
    source == "manual"
  end
end
