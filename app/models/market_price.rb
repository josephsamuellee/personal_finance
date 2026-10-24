class MarketPrice < ApplicationRecord
  belongs_to :security
  belongs_to :entered_by, class_name: "User", optional: true

  validates :amount, :market_on, :retrieved_at, :source, :currency, :adjustment_convention, presence: true
  validates :amount, numericality: { greater_than: 0 }

  def self.usable_on(security, date)
    where(security: security, market_on: ..date).order(market_on: :desc, retrieved_at: :desc).first
  end

  # The effective price saved exactly on this market date; no carry-forward
  # from an earlier date (use usable_on for valuation).
  def self.effective_on(security, date)
    find_by(security: security, market_on: date)
  end

  # Save one effective price for the security, market date, currency, and
  # adjustment convention, updating the existing effective price for that
  # date instead of accumulating duplicates.
  def self.upsert_effective!(security:, amount:, market_on:, currency:, source:, entered_by: nil,
                            retrieved_at: Time.current, adjustment_convention: "raw")
    existing = find_by(security:, market_on:, currency:, adjustment_convention:)
    if existing
      existing.update!(amount:, source:, retrieved_at:, entered_by:)
      existing
    else
      create!(security:, amount:, market_on:, currency:, source:, entered_by:, retrieved_at:, adjustment_convention:)
    end
  end

  def manual?
    source == "manual"
  end
end
