module Reporting
  class Spending
    def self.total(range)
      Expense.tracked.where(spent_on: range).sum(:amount)
    end

    def self.by_category(range)
      Expense.tracked.where(spent_on: range).left_joins(:expense_category).group("expense_categories.name").sum(:amount)
    end

    def self.baseline(on = Date.current)
      ranges = completed_month_ranges(on, 3)
      totals = ranges.map { |range| total(range) }
      {
        months: ranges.map(&:begin),
        totals: totals,
        average: totals.sum(BigDecimal("0")) / ranges.size
      }
    end

    def self.completed_month_ranges(on, count)
      anchor = on.beginning_of_month - 1
      count.times.map do |offset|
        (anchor << offset).all_month
      end
    end

    def self.month_to_date(on = Date.current)
      total(on.beginning_of_month..on)
    end

    def self.daily_chart(on = Date.current)
      start_on = on.beginning_of_month << 2
      totals = Expense.tracked.where(spent_on: start_on..on).group(:spent_on).sum(:amount)
      running = Hash.new(BigDecimal("0"))
      (start_on..on).map do |day|
        month = day.beginning_of_month
        amount = totals.fetch(day, BigDecimal("0"))
        running[month] += amount
        {
          date: day.iso8601,
          amount: amount.to_s("F"),
          cumulative: running[month].to_s("F")
        }
      end
    end
  end
end
