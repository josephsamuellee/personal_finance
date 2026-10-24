class AccountsController < ApplicationController
  before_action :set_account, only: %i[ show edit update destroy ]

  def index
    @accounts = Account.order(:name)
  end

  def show
    @observations = @account.account_observations.kept.order(observed_on: :desc, sequence: :desc)
  end

  def new
    @account = Account.new(currency: "USD")
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to accounts_path, notice: "Account saved."
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

  private
    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :account_type, :currency)
    end
end
