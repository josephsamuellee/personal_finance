class SecuritiesController < ApplicationController
  def create
    @security = Security.new(security_params)
    @form = "security"
    @price = MarketPrice.new(currency: "USD", market_on: Date.current)
    @action_values = {}
    if @security.save
      redirect_to asset_maintenance_path(form: "security"), notice: "Security saved."
    else
      render "asset_maintenance/show", status: :unprocessable_entity
    end
  end

  private
    def security_params
      params.require(:security).permit(:ticker, :note, :currency)
    end
end
