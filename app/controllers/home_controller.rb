class HomeController < ApplicationController
  def index
    @on = Date.current
    @snapshot = Reporting::Snapshot.new(on: @on)
    @baseline = Reporting::Spending.baseline(@on)
    @month_spending = Reporting::Spending.month_to_date(@on)
    @previous_spending = Reporting::Spending.total((@on.beginning_of_month - 1).all_month)
    @spending_chart = Reporting::Spending.daily_chart(@on)
    @surplus = Reporting::Surplus.estimate(@on)
    @insights = Reporting::Insights.build(on: @on)
    @history = Reporting::Series.net_worth_history
    @recent_review = FinancialReview.order(review_on: :desc).first
  rescue ActiveRecord::StatementInvalid
    @load_error = true
  end
end
