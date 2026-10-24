module Reporting
  class Surplus
    def self.estimate(on = Date.current)
      income = RecurringItem.monthly_total(on, direction: "income")
      obligations = RecurringItem.monthly_total(on, direction: "obligation", treatment: "additional")
      baseline = Spending.baseline(on)
      amount = income - baseline[:average] - obligations
      {
        amount: amount,
        income: income,
        obligations: obligations,
        baseline: baseline,
        label: "Estimate"
      }
    end

    def self.below_target_message(on = Date.current)
      months = [ 1, 2 ].map { |offset| (on.beginning_of_month - 1) << (offset - 1) }
      return if months.any? { |month| SavingsGoal.applicable_on(month.end_of_month).nil? }

      below = months.all? do |month|
        as_of = month.end_of_month
        estimate(as_of)[:amount] < SavingsGoal.applicable_on(as_of).amount
      end
      return unless below

      "Estimated monthly surplus has been below the savings target for two consecutive months. This alert is informational."
    end
  end
end
