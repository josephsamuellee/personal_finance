class HoldingsController < ApplicationController
  def index
    prepare_assets_page
  end

  def show
    @account = Account.find(params[:account_id])
    @security = Security.find(params[:security_id])
    @observations = PositionObservation.kept.where(account: @account, security: @security).order(:observed_on, :sequence)
    @on = parse_date(params[:on]) || Date.current
    state, row = PositionObservation.state_on({ account_id: @account.id, security_id: @security.id }, @on)
    @state = state
    @current = row
  end

  def update_position
    account = Account.available_for_entry.find(params[:account_id])
    security = Security.find(params[:security_id])
    holding_form = ::HoldingForm.new(
      account:, security:, user: current_user,
      gesture: params[:gesture].presence || "save",
      observed_on: params[:observed_on],
      quantity: params[:quantity], cost_basis: params[:cost_basis],
      price: params[:price], note: params[:note], reason: params[:reason].presence,
      historical_ack: params[:historical_ack], correction_id: params[:id]
    )

    if holding_form.valid?
      save_holding(holding_form)
    else
      show_holding_errors(holding_form, account, security)
    end
  rescue Date::Error
    redirect_to assets_path, alert: "Enter a valid date."
  end

  def new
    prepare_holding_form
  end

  def create
    account = Account.available_for_entry.brokerage.find(params[:account_id])
    holding_form = ::HoldingForm.new(
      account:, security: Security.find_by(id: params[:security_id]),
      user: current_user, gesture: "create",
      ticker: params[:ticker], exchange: params[:exchange], currency: params[:currency],
      note: params[:note], observed_on: params[:observed_on],
      quantity: params[:quantity], cost_basis: params[:cost_basis], price: params[:price],
      historical_ack: params[:historical_ack]
    )

    if holding_form.valid?
      holding_form.save!
      redirect_to assets_path(on: holding_form.observed_on), notice: "Holding saved."
    else
      prepare_holding_form(errors: holding_form.errors, security: holding_form.security)
      render :new, status: :unprocessable_entity
    end
  end

  def update_balance
    account = Account.available_for_entry.find(params[:account_id])
    observed_on = Date.parse(params[:observed_on])
    if observed_on > Date.current
      return redirect_to assets_path, alert: "Observation dates cannot be in the future."
    end
    if observed_on < Date.current && params[:historical_ack] != "1"
      prepare_assets_page(on: observed_on)
      @balance_editor = balance_editor_for(account, observed_on, amount: params[:amount], errors: historical_ack_errors)
      return render :index, status: :unprocessable_entity
    end

    values = { amount: params[:amount], notes: params[:notes] }

    case params[:gesture]
    when "add"
      AccountObservation.add_another!({ account: }, observed_on:, updated_by: current_user, **values)
    when "correct"
      observation = AccountObservation.kept.find(params[:id])
      observation.revision_user = current_user
      observation.revision_reason = params[:revision_reason]
      observation.update!(values.merge(observed_on: params[:observed_on].presence || observation.observed_on, updated_by: current_user))
    else
      AccountObservation.revise_current!({ account: }, observed_on:, updated_by: current_user, **values)
    end
    redirect_to assets_path(on: observed_on), notice: "Balance saved."
  rescue ActiveRecord::RecordInvalid => error
    prepare_assets_page(on: observed_on)
    @balance_editor = balance_editor_for(account, observed_on, amount: params[:amount], errors: error.record.errors)
    render :index, status: :unprocessable_entity
  rescue Date::Error
    redirect_to assets_path, alert: "Enter a valid date."
  end

  private
    def prepare_holding_form(errors: nil, security: nil)
      @account = Account.available_for_entry.brokerage.find(params[:account_id])
      @securities = Security.order(:ticker)
      @security = security || Security.find_by(id: params[:security_id])
      @observed_on = parse_date(params[:observed_on]) || Date.current
      @exact_price = @security ? MarketPrice.effective_on(@security, @observed_on) : nil
      @price_value = params[:price].presence || @exact_price&.amount
      @values = params
      @errors = errors
    end

    def save_holding(holding_form)
      result = holding_form.save!
      case result[:intent]
      when :no_change
        redirect_to assets_path(on: holding_form.observed_on), notice: "Nothing changed, so nothing was saved."
      when :price_only
        redirect_to assets_path(on: holding_form.observed_on), notice: "Price saved."
      else
        redirect_to assets_path(on: holding_form.observed_on), notice: "Holding saved."
      end
    end

    def show_holding_errors(holding_form, account, security)
      observed_on = holding_form.observed_on || parse_date(params[:observed_on]) || Date.current
      if params[:reason] == "corporate_action"
        @form = "action"
        @action_values = params
        @errors = holding_form.errors
        render "asset_maintenance/show", status: :unprocessable_entity
      else
        prepare_assets_page(on: observed_on)
        @editor = editor_for(account, security, observed_on,
                             quantity: params[:quantity], cost_basis: params[:cost_basis],
                             price: params[:price], errors: holding_form.errors)
        render :index, status: :unprocessable_entity
      end
    end

    def prepare_assets_page(on: nil)
      @on = on || selected_date
      @group = params[:group]
      @accounts = accounts_for_group
      @states = @accounts.map { |account| [ account.id, AccountObservation.state_on({ account_id: account.id }, @on) ] }.to_h
      @positions = position_rows
      @snapshot = Reporting::Snapshot.new(on: @on) if @accounts.any? || @positions.any?
      @cards = @accounts.map { |account| account_card(account) }
      @editor = build_editor
      @balance_editor = build_balance_editor
    rescue ActiveRecord::StatementInvalid
      @load_error = true
    end

    def selected_date
      if params[:edit].present? && (editor_on = parse_date(params[:observed_on]))
        editor_on
      else
        parse_date(params[:on]) || Date.current
      end
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end

    def accounts_for_group
      scope = Account.order(:name).select { |account| account.visible_on?(@on) }
      scope = Account.where(id: scope.map(&:id)).order(:name)
      case @group
      when "cash" then scope.where(account_type: %w[checking savings brokerage])
      when "property" then scope.property
      when "debt" then scope.debt
      when "investments" then scope.brokerage
      else scope
      end
    end

    def account_card(account)
      holdings = @positions.select { |position| position[:account].id == account.id }
      state, row = @states[account.id]
      cash_row = account.brokerage? ? AccountObservation.current_on({ account_id: account.id }, @on) : row
      cash_amount = account.brokerage? ? cash_row&.amount.to_d : nil
      cash_observed = account.brokerage? && AccountObservation.kept.where(account: account).exists?
      show_cash_row = cash_observed && !cash_amount.to_d.zero?
      missing_price = holdings.any? { |holding| holding[:row] && !holding[:row].closed? && holding[:market_value].nil? }
      incomplete = if account.brokerage?
        holdings.any? && missing_price
      else
        row.nil? || missing_price
      end
      amount = if incomplete
        nil
      elsif account.brokerage?
        cash_amount + holdings.sum { |holding| holding[:market_value].to_d }
      else
        total = row.amount.to_d + holdings.sum { |holding| holding[:market_value].to_d }
        account.debt? ? -total : total
      end
      display_state, display_row = if account.brokerage? && holdings.any?
        [ holdings.first[:state], holdings.first[:row] ]
      else
        [ state, cash_row ]
      end
      { account:, state: display_state, row: display_row, holdings:, amount:, incomplete:,
        cash_amount:, show_cash_row: }
    end

    def position_rows
      return [] if @group.present? && @group != "investments"

      PositionObservation.kept.where(observed_on: ..@on).distinct.pluck(:account_id, :security_id).filter_map do |account_id, security_id|
        account = Account.available_for_entry.find_by(id: account_id)
        next if account.nil?

        security = Security.find(security_id)
        state, row = PositionObservation.state_on({ account_id:, security_id: }, @on)
        price = MarketPrice.usable_on(security, @on)
        market_value = if row&.closed?
          0
        elsif price && price.currency == "USD" && security.currency == "USD"
          row.quantity * price.amount
        end
        { account:, security:, state:, row:, price:, market_value: }
      end
    end

    def build_editor
      return if params[:edit].blank?

      account_id, security_id = params[:edit].to_s.split("-", 2)
      account = Account.available_for_entry.find_by(id: account_id)
      security = Security.find_by(id: security_id)
      return unless account && security

      observed_on = parse_date(params[:observed_on]) || @on
      editor_for(account, security, observed_on, quantity: params[:quantity], cost_basis: params[:cost_basis])
    end

    def editor_for(account, security, observed_on, quantity:, cost_basis:, price: nil, errors: nil)
      state, row = PositionObservation.state_on({ account_id: account.id, security_id: security.id }, observed_on)
      on_date = PositionObservation.kept.where(account:, security:, observed_on:).order(sequence: :desc).first
      unless errors
        quantity = quantity.presence || on_date&.quantity || row&.quantity
        cost_basis = cost_basis.presence || on_date&.cost_basis || row&.cost_basis
      end
      exact_price = MarketPrice.effective_on(security, observed_on)
      price_value = price.presence || exact_price&.amount
      {
        account:, security:, observed_on:, state:, row:, on_date:, quantity:, cost_basis:,
        exact_price:, price: price_value, errors:,
        latest_price: MarketPrice.usable_on(security, observed_on),
        last_verified_on: PositionObservation.kept.where(account:, security:).order(observed_on: :desc, sequence: :desc).pick(:observed_on),
        intent: holding_intent_label(account, security, observed_on, quantity:, cost_basis:, price: price_value)
      }
    end

    def holding_intent_label(account, security, observed_on, quantity:, cost_basis:, price:)
      ::HoldingForm.new(account:, security:, gesture: "save",
                      observed_on: observed_on.iso8601, quantity:, cost_basis:, price:)
                  .intent_label
    end

    def historical_ack_errors
      errors = ActiveModel::Errors.new(Account.new)
      errors.add(:historical_ack, "must be acknowledged to save a past date")
      errors
    end

    def build_balance_editor
      return if params[:balance].blank?

      account = Account.available_for_entry.find_by(id: params[:balance])
      observed_on = parse_date(params[:balance_on]) || @on
      balance_editor_for(account, observed_on, amount: params[:amount])
    end

    def balance_editor_for(account, observed_on, amount:, errors: nil)
      state, row = account ? AccountObservation.state_on({ account_id: account.id }, observed_on) : [ nil, nil ]
      {
        account:, observed_on:, state:, row:, errors:,
        amount: amount.presence || row&.amount
      }
    end
end
