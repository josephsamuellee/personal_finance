module Reporting
  class Insights
    Insight = Struct.new(:kind, :text, :required, keyword_init: true)

    def self.build(on: Date.current)
      insights = []
      insights << spending_insight(on)
      insights.concat(carried_holding_insights(on))
      insights.concat(upcoming_obligation_insights(on))
      alert = Surplus.below_target_message(on)
      insights << Insight.new(kind: "suggestion", text: alert, required: false) if alert
      insights.compact.each { |insight| insight.required = false }
    end

    def self.spending_insight(on)
      spent = Spending.month_to_date(on)
      average = Spending.baseline(on)[:average]
      return if spent <= average

      timing = on < on.end_of_month ? "Month-to-date tracked spending" : "Tracked spending"
      Insight.new(
        kind: "estimate",
        text: "#{timing} of #{spent} is above the three-month tracked spending baseline of #{average}.",
        required: false
      )
    end

    def self.carried_holding_insights(on)
      PositionObservation.kept.where(observed_on: ..on).distinct.pluck(:account_id, :security_id).filter_map do |account_id, security_id|
        state, row = PositionObservation.state_on({ account_id:, security_id: }, on)
        next unless state == :carried_forward

        security = Security.find(security_id)
        Insight.new(
          kind: "fact",
          text: "#{security.ticker} quantity is carried forward from #{row.observed_on.iso8601}.",
          required: false
        )
      end
    end

    def self.upcoming_obligation_insights(on)
      horizon = on + 31
      RecurringItem.obligation.filter_map do |item|
        occurrence = item.next_occurrence_on(from: on)
        next if occurrence.nil? || occurrence > horizon

        Insight.new(
          kind: "fact",
          text: "#{item.name} is upcoming on #{occurrence.iso8601}.",
          required: false
        )
      end
    end
  end
end
