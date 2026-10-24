class MarketPricesController < ApplicationController
  def create
    @price = MarketPrice.new(price_params)
    @price.source = "manual"
    @price.retrieved_at = Time.current
    @price.entered_by = current_user
    @form = "price"
    @security = Security.new(currency: "USD")
    @action_values = {}
    if @price.save
      redirect_to asset_maintenance_path(form: "price"), notice: "Price saved."
    else
      render "asset_maintenance/show", status: :unprocessable_entity
    end
  end

  def refresh
    result = MarketData::Refresh.new.call
    if result.partial?
      redirect_to assets_path, alert: "Price refresh was partial. Failed: #{result.failed.map(&:ticker).to_sentence}. Cached prices were kept."
    elsif result.failure?
      redirect_to assets_path, alert: "Price refresh failed. Cached prices were kept."
    elsif result.updated.any?
      stamp = MarketPrice.where(security: result.updated).maximum(:retrieved_at)
      redirect_to assets_path, notice: "Prices refreshed. Latest price #{stamp&.iso8601}."
    else
      redirect_to assets_path, notice: "Prices refreshed."
    end
  end

  private
    def price_params
      params.require(:market_price).permit(:security_id, :amount, :currency, :market_on)
    end
end
