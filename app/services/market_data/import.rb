module MarketData
  # Fetches historical prices for a security and inclusive date range on
  # explicit request, caching them in the local database with full metadata.
  # Manually entered prices are preserved unless replace: true.
  class Import
    class << self
      attr_accessor :adapter
    end

    Result = Struct.new(:imported, :kept_manual, :failed, keyword_init: true)

    def initialize(adapter: nil)
      @adapter = adapter || self.class.adapter || AlphaVantage.new
    end

    def call(security, from:, to:, replace: false)
      records = @adapter.history(security, from:, to:)
      imported = 0
      kept_manual = 0
      records.each do |record|
        market_on = record.fetch(:market_on)
        currency = record.fetch(:currency)
        adjustment_convention = record.fetch(:adjustment_convention, "raw")
        existing = MarketPrice.find_by(security:, market_on:, currency:, adjustment_convention:)
        if existing&.manual? && !replace
          kept_manual += 1
          next
        end

        MarketPrice.upsert_effective!(
          security:, amount: record.fetch(:amount), market_on:, currency:,
          source: @adapter.class::NAME, retrieved_at: Time.current,
          adjustment_convention:
        )
        imported += 1
      end
      Result.new(imported:, kept_manual:)
    rescue ProviderError
      Result.new(imported: 0, kept_manual: 0, failed: security)
    end
  end
end
