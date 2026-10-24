module MarketData
  class ProviderError < StandardError; end

  class Adapter
    def quote(_security)
      raise NotImplementedError
    end

    # Returns an array of { amount:, market_on:, currency:, adjustment_convention: }
    # records for the inclusive date range. Non-trading dates return no record.
    def history(_security, from:, to:)
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

    def history(security, from:, to:)
      key = ENV["ALPHAVANTAGE_API_KEY"]
      raise ProviderError, "#{NAME} is not configured" if key.blank?

      uri = URI("https://www.alphavantage.co/query")
      uri.query = URI.encode_www_form(function: "TIME_SERIES_DAILY", symbol: security.ticker, apikey: key, outputsize: "full")
      response = Net::HTTP.get_response(uri)
      raise ProviderError, "#{NAME} request failed" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      series = payload["Time Series (Daily)"]
      raise ProviderError, "#{NAME} did not return a series for #{security.ticker}" if series.blank?

      series.filter_map do |date, row|
        market_on = Date.parse(date)
        next unless (from..to).cover?(market_on)

        close = row["4. close"]
        next if close.blank?

        { amount: BigDecimal(close), market_on:, currency: "USD", adjustment_convention: "raw" }
      rescue Date::Error
        raise ProviderError, "#{NAME} returned an unparseable date for #{security.ticker}"
      end
    end
  end

  class Refresh
    class << self
      attr_accessor :adapter
    end

    Result = Struct.new(:updated, :failed, :kept_manual, keyword_init: true) do
      def partial?
        updated.any? && failed.any?
      end

      def failure?
        updated.empty? && failed.any?
      end
    end

    def initialize(adapter: nil, account: nil, on: Date.current)
      @adapter = adapter || self.class.adapter || AlphaVantage.new
      @account = account
      @on = on
    end

    def call
      updated = []
      failed = []
      kept_manual = []
      relevant_securities.each do |security|
        existing_on_date = MarketPrice.effective_on(security, @on)
        if existing_on_date&.manual?
          kept_manual << security
          next
        end
        if existing_on_date && !existing_on_date.manual?
          next
        end

        data = @adapter.quote(security)
        existing = MarketPrice.effective_on(security, data.fetch(:market_on))
        if existing&.manual?
          kept_manual << security
          next
        end

        MarketPrice.upsert_effective!(
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
      Result.new(updated:, failed:, kept_manual:)
    end

    private
      def relevant_securities
        Security.where(id: held_security_ids).distinct.order(:ticker)
      end

      def held_security_ids
        scope = PositionObservation.kept.where(observed_on: ..@on)
        scope = scope.where(account: @account) if @account
        scope.distinct.pluck(:account_id, :security_id).filter_map do |account_id, security_id|
          next if @account && account_id != @account.id

          row = PositionObservation.current_on({ account_id:, security_id: }, @on)
          security_id if row && row.quantity.to_d.positive?
        end
      end
  end
end
