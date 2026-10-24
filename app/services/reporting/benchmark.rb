module Reporting
  class Benchmark
    def initialize(from:, to:, cash_flows_recorded:)
      @from = from
      @to = to
      @cash_flows_recorded = cash_flows_recorded
    end

    def value_change
      {
        from: portfolio_value(@from),
        to: portfolio_value(@to),
        amount: portfolio_value(@to) - portfolio_value(@from),
        label: "Change in portfolio value"
      }
    end

    def performance
      return incomplete_performance unless @cash_flows_recorded

      starting = portfolio_value(@from)
      ending = portfolio_value(@to)
      voo_start = voo_price(@from)
      voo_end = voo_price(@to)
      return incomplete_performance if voo_start.nil? || voo_end.nil? || starting.zero?

      growth = ending - starting - net_external_flows
      {
        available: true,
        portfolio_return: growth / starting,
        voo_return: (voo_end / voo_start) - 1,
        label: "Adjusted for the recorded cash flows"
      }
    end

    private
      def incomplete_performance
        {
          available: false,
          label: "A precise outperformance figure is not available because external cash flows in this period are incomplete."
        }
      end

      def portfolio_value(date)
        Reporting::Snapshot.new(on: date).components
          .select { |component| component.group == "Investments" && component.amount }
          .sum { |component| component.amount.to_d }
      end

      def voo_price(date)
        security = Security.find_by(ticker: "VOO")
        return if security.nil?

        MarketPrice.usable_on(security, date)&.amount
      end

      def net_external_flows
        brokerage_ids = Account.brokerage.pluck(:id)
        Expense.kept.transfer.where(spent_on: @from.next_day..@to).sum do |transfer|
          into = brokerage_ids.include?(transfer.destination_account_id)
          out = brokerage_ids.include?(transfer.source_account_id)
          if into && !out
            transfer.amount
          elsif out && !into
            -transfer.amount
          else
            0
          end
        end
      end
  end
end
