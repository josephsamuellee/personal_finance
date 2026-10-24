class Security < ApplicationRecord
  has_many :position_observations, dependent: :destroy
  has_many :market_prices, dependent: :destroy

  validates :ticker, :identifier, :currency, presence: true
  validates :ticker, uniqueness: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }

  normalizes :ticker, with: ->(value) { value.to_s.strip.upcase }
end
