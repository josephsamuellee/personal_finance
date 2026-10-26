require "csv"

module HoldingsImport
  class BulkExport
    def initialize(on:)
      @on = on
    end

    def holdings
      @holdings ||= OpenHoldings.on(@on)
    end

    def too_large?
      holdings.size > HoldingCsv::MAX_ROWS
    end

    def to_csv
      CSV.generate do |csv|
        csv << HoldingCsv::BULK_HEADERS
        holdings.each { |holding| csv << row_for(holding) }
      end
    end

    private
      def row_for(holding)
        security = holding.security
        [
          holding.account.id,
          HoldingCsv.to_spreadsheet_text(holding.account.name),
          security.ticker,
          HoldingCsv.to_spreadsheet_text(security.note),
          security.currency,
          @on.iso8601,
          plain(holding.observation.quantity),
          plain(holding.observation.cost_basis),
          nil,
          plain(MarketPrice.usable_on(security, @on)&.amount)
        ]
      end

      def plain(number)
        number&.to_d&.to_s("F")&.delete_suffix(".0")
      end
  end
end
