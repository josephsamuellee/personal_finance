module Reporting
  class Series
    def self.detailed(scope)
      scope.kept.order(:observed_on, :sequence).map do |observation|
        {
          date: observation.observed_on.iso8601,
          amount: observation.respond_to?(:quantity) ? observation.quantity.to_s : observation.amount.to_s,
          sequence: observation.sequence
        }
      end
    end

    def self.monthly_latest(scope)
      grouped = scope.kept.order(:observed_on, :sequence).group_by { |observation| observation.observed_on.strftime("%Y-%m") }
      grouped.map do |month, rows|
        current = rows.max_by { |row| [ row.observed_on, row.sequence ] }
        {
          month: month,
          date: current.observed_on.iso8601,
          amount: current.respond_to?(:quantity) ? current.quantity.to_s : current.amount.to_s
        }
      end
    end

    def self.net_worth_history
      dates = (
        AccountObservation.kept.distinct.pluck(:observed_on) +
        PositionObservation.kept.distinct.pluck(:observed_on)
      ).uniq.sort
      dates.map do |date|
        snapshot = Snapshot.new(on: date)
        {
          date: date.iso8601,
          amount: snapshot.net_worth.to_s,
          quality: snapshot.quality_label
        }
      end
    end
  end
end
