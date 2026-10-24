class ComparisonsController < ApplicationController
  def show
    @on = parse_date(params[:on]) || Date.current
    @against = params[:against].presence || "prior_month"
    @other_on = other_date
    @current = Reporting::Snapshot.new(on: @on)
    @other = Reporting::Snapshot.new(on: @other_on)
    @current_spending = Reporting::Spending.total(@on.all_month)
    @other_spending = Reporting::Spending.total(@other_on.all_month)
  end

  private
    def other_date
      case @against
      when "prior_year" then @on.prev_year
      when "prior_observation"
        earlier = AccountObservation.kept.where(observed_on: ...@on).maximum(:observed_on)
        earlier || @on
      else
        @on.prev_month
      end
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
