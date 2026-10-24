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
    observed_on = Date.parse(params[:observed_on])
    values = position_values

    case params[:gesture]
    when "add"
      PositionObservation.add_another!({ account:, security: }, observed_on:, updated_by: current_user, **values)
    when "correct"
      observation = PositionObservation.kept.find(params[:id])
      observation.revision_user = current_user
      observation.revision_reason = params[:revision_reason]
      observation.update!(values.merge(observed_on: params[:observed_on].presence || observation.observed_on, updated_by: current_user))
    else
      PositionObservation.revise_current!({ account:, security: }, observed_on:, updated_by: current_user, **values)
    end
    redirect_to assets_path(on: observed_on), notice: "Holding saved."
  rescue ActiveRecord::RecordInvalid => error
    if params[:reason] == "corporate_action"
      @form = "action"
      @action_values = params
      @errors = error.record.errors
      render "asset_maintenance/show", status: :unprocessable_entity
    else
      prepare_assets_page(on: observed_on)
      @editor = editor_for(account, security, observed_on, quantity: params[:quantity], cost_basis: params[:cost_basis], errors: error.record.errors)
      render :index, status: :unprocessable_entity
    end
  rescue Date::Error
    redirect_to assets_path, alert: "Enter a valid date."
  end

  def update_balance
    account = Account.available_for_entry.find(params[:account_id])
    observed_on = Date.parse(params[:observed_on])
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
      scope = Account.available_for_entry.order(:name)
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
      missing_price = holdings.any? { |holding| holding[:row] && !holding[:row].closed? && holding[:market_value].nil? }
      incomplete = row.nil? || missing_price
      amount = if incomplete
        nil
      else
        total = row.amount.to_d + holdings.sum { |holding| holding[:market_value].to_d }
        account.debt? ? -total : total
      end
      { account:, state:, row:, holdings:, amount:, incomplete: }
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

    def position_values
      { quantity: params[:quantity], cost_basis: params[:cost_basis], notes: params[:notes], reason: params[:reason].presence }
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

    def editor_for(account, security, observed_on, quantity:, cost_basis:, errors: nil)
      state, row = PositionObservation.state_on({ account_id: account.id, security_id: security.id }, observed_on)
      on_date = PositionObservation.kept.where(account:, security:, observed_on:).order(sequence: :desc).first
      unless errors
        quantity = quantity.presence || on_date&.quantity || row&.quantity
        cost_basis = cost_basis.presence || on_date&.cost_basis || row&.cost_basis
      end
      price = MarketPrice.usable_on(security, observed_on)
      {
        account:, security:, observed_on:, state:, row:, on_date:, quantity:, cost_basis:, price:, errors:,
        last_verified_on: PositionObservation.kept.where(account:, security:).order(observed_on: :desc, sequence: :desc).pick(:observed_on),
        intent: editor_intent(on_date, quantity, cost_basis)
      }
    end

    def editor_intent(on_date, quantity, cost_basis)
      return "New observation" if on_date.nil?
      return "Edit observation" unless same_number?(on_date.quantity, quantity) && same_number?(on_date.cost_basis, cost_basis)

      "Verify"
    end

    def same_number?(left, right)
      return false if left.blank? || right.blank?

      BigDecimal(left.to_s) == BigDecimal(right.to_s)
    rescue ArgumentError
      false
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
