class ChartsController < ApplicationController
  def observations
    scope = if params[:security_id].present?
      PositionObservation.where(account_id: params[:account_id], security_id: params[:security_id])
    else
      AccountObservation.where(account_id: params[:account_id])
    end
    render json: {
      detailed: Reporting::Series.detailed(scope),
      monthly: Reporting::Series.monthly_latest(scope)
    }
  end

  def net_worth
    render json: Reporting::Series.net_worth_history
  end
end
