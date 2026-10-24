module MarketData
  class ProviderError < StandardError; end

  class Adapter
    def quote(_security)
      raise NotImplementedError
    end
  end

  class AlphaVantage < Adapter
    NAME = "Alpha Vantage"

    def quote(security)
      key = ENV["ALPHAVANTAGE_API_KEY"]
      raise ProviderError, "#{NAME} is not configured" if key.blank?

      uri = URI("https://www.alphavantage.co/query")
      uri.query = URI.encode_www_form(function: "GLOBAL_QUOTE", symbol: security.ticker, apikey: key)
      response = Net::HTTP.get_response(uri)
      raise ProviderError, "#{NAME} request failed" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      quote = payload["Global Quote"]
      price = quote && quote["05. price"]
      traded_on = quote && quote["07. latest trading day"]
      raise ProviderError, "#{NAME} did not return a price for #{security.ticker}" if price.blank? || traded_on.blank?

      { amount: BigDecimal(price), market_on: Date.parse(traded_on), currency: "USD" }
    end
  end

  class Refresh
    class << self
      attr_accessor :adapter
    end

    Result = Struct.new(:updated, :failed, keyword_init: true) do
      def partial?
        updated.any? && failed.any?
      end

      def failure?
        updated.empty? && failed.any?
      end
    end

    def initialize(adapter: nil)
      @adapter = adapter || self.class.adapter || AlphaVantage.new
    end

    def call
      updated = []
      failed = []
      relevant_securities.each do |security|
        data = @adapter.quote(security)
        MarketPrice.create!(
          security: security,
          amount: data.fetch(:amount),
          currency: data.fetch(:currency),
          market_on: data.fetch(:market_on),
          retrieved_at: Time.current,
          source: @adapter.class::NAME
        )
        updated << security
      rescue ProviderError
        failed << security
      end
      Result.new(updated:, failed:)
    end

    private
      def relevant_securities
        Security.where(id: PositionObservation.kept.where("quantity > 0").select(:security_id)).distinct.order(:ticker)
      end
  end
end
