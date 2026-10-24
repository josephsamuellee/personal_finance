class AccountsController < ApplicationController
  before_action :set_account, only: %i[ show edit update destroy restore refresh_prices ]

  def index
    @accounts = Account.order(:name)
  end

  def show
    @observations = @account.account_observations.kept.order(observed_on: :desc, sequence: :desc)
    @on = begin
      Date.iso8601(params.fetch(:on, Date.current.iso8601))
    rescue Date::Error
      Date.current
    end
    @holdings = account_holdings
  end

  def new
    @account = Account.new(currency: "USD")
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      if @account.brokerage?
        redirect_to new_account_holdings_import_path(@account), notice: "Account saved."
      else
        redirect_to accounts_path, notice: "Account saved."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:archive] == "1"
      @account.archive!
      redirect_to accounts_path, notice: "Account archived."
    elsif @account.update(account_params)
      redirect_to accounts_path, notice: "Account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.archive!
    redirect_to accounts_path, notice: "Account archived."
  end

  def restore
    @account.unarchive!
    redirect_to account_path(@account), notice: "Account restored."
  end

  def refresh_prices
    on = begin
      Date.iso8601(params.fetch(:on, Date.current.iso8601))
    rescue Date::Error
      Date.current
    end
    result = MarketData::Refresh.new(account: @account, on:).call
    if result.partial?
      redirect_to account_path(@account, on:), alert: "Price refresh was partial. Failed: #{result.failed.map(&:ticker).to_sentence}."
    elsif result.failure?
      redirect_to account_path(@account, on:), alert: "Price refresh failed. Cached prices were kept."
    else
      redirect_to account_path(@account, on:), notice: refresh_notice(result)
    end
  end

  private
    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :account_type, :currency)
    end

    def refresh_notice(result)
      parts = [ "Prices refreshed." ]
      parts << "Kept #{result.kept_manual.map(&:ticker).to_sentence} as manual." if result.kept_manual.any?
      parts.join(" ")
    end

    def account_holdings
      PositionObservation.kept.where(account: @account, observed_on: ..@on)
                         .distinct.pluck(:security_id).filter_map do |security_id|
        security = Security.find(security_id)
        state, row = PositionObservation.state_on({ account_id: @account.id, security_id: }, @on)
        price = MarketPrice.usable_on(security, @on)
        market_value = if row&.closed?
          0
        elsif price && price.currency == "USD" && security.currency == "USD" && row
          row.quantity * price.amount
        end
        { security:, state:, row:, price:, market_value: }
      end
    end
end
