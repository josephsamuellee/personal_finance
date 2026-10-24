class AssetMaintenanceController < ApplicationController
  def show
    @form = params[:form].presence_in(%w[security price import action])
    @security = Security.new(currency: "USD")
    @price = MarketPrice.new(currency: "USD", market_on: Date.current)
    @action_values = { account_id: params[:account_id] }
    @selected_account = Account.available_for_entry.find_by(id: params[:account_id])
  end
end
