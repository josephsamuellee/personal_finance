class MarketPricesController < ApplicationController
  def create
    @price = MarketPrice.new(price_params)
    @price.source = "manual"
    @price.retrieved_at = Time.current
    @price.entered_by = current_user
    @form = "price"
    @security = Security.new(currency: "USD")
    @action_values = {}
    if @price.valid?
      MarketPrice.upsert_effective!(
        security: @price.security,
        amount: @price.amount,
        market_on: @price.market_on,
        currency: @price.currency,
        source: "manual",
        entered_by: current_user
      )
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

  def import
    security = Security.find(params[:security_id])
    from = Date.iso8601(params[:from])
    to = Date.iso8601(params[:to])
    result = MarketData::Import.new.call(security, from:, to:, replace: params[:replace] == "1")
    if result.failed
      redirect_to asset_maintenance_path(form: "import"), alert: "Import failed for #{security.ticker}. Cached prices were kept."
    else
      notice = "Imported #{result.imported} price#{result.imported == 1 ? '' : 's'} for #{security.ticker}."
      notice += " Kept #{result.kept_manual} manual price#{result.kept_manual == 1 ? '' : 's'}." if result.kept_manual.positive?
      redirect_to asset_maintenance_path(form: "import"), notice:
    end
  rescue Date::Error, ActiveRecord::RecordNotFound
    redirect_to asset_maintenance_path(form: "import"), alert: "Choose a security and valid dates."
  end

  private
    def price_params
      params.require(:market_price).permit(:security_id, :amount, :currency, :market_on)
    end
end
