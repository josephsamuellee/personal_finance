class BenchmarksController < ApplicationController
  def show
    @from = parse_date(params[:from]) || Date.current.prev_year
    @to = parse_date(params[:to]) || Date.current
    recorded = ActiveModel::Type::Boolean.new.cast(params[:cash_flows_recorded])
    benchmark = Reporting::Benchmark.new(from: @from, to: @to, cash_flows_recorded: recorded)
    @value_change = benchmark.value_change
    @performance = benchmark.performance
  end

  private
    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
