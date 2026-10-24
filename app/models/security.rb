class Security < ApplicationRecord
  has_many :position_observations, dependent: :destroy
  has_many :market_prices, dependent: :destroy

  validates :ticker, :currency, presence: true
  validates :ticker, uniqueness: { scope: :exchange }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }

  normalizes :ticker, with: ->(value) { value.to_s.strip.upcase }
  normalizes :exchange, with: ->(value) { value.to_s.strip.upcase.presence }

  # Reuse the shared security for an identity (ticker + optional exchange)
  # instead of creating a duplicate record when adding a holding elsewhere.
  # A note supplied with an existing identity updates the shared note.
  def self.find_or_create_by_identity!(ticker:, exchange: nil, currency: "USD", note: nil)
    exchange = exchange.presence
    existing = find_by(ticker:, exchange:)
    if existing
      existing.update!(note:) if note.present?
      return existing
    end

    create!(ticker:, exchange:, currency:, note:)
  end
end
