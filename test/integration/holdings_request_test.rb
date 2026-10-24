require "test_helper"

class HoldingsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
    @account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @other = Account.create!(name: "IRA", account_type: "brokerage", currency: "USD")
    @voo = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    @qqq = Security.create!(ticker: "QQQ", identifier: "QQQ", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: @voo }, observed_on: Date.new(2026, 3, 15), updated_by: @user, quantity: 50, cost_basis: 10)
    PositionObservation.revise_current!({ account: @other, security: @qqq }, observed_on: Date.new(2026, 3, 15), updated_by: @user, quantity: 3, cost_basis: 10)
  end

  test "verify save marks one holding verified and leaves the other carried forward" do
    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: "2026-10-21",
      gesture: "verify", quantity: "50", cost_basis: "10", historical_ack: "1"
    }
    follow_redirect!
    assert_includes response.body, "Verified"
    assert_not_includes response.body, "Carried forward from 2026-03-15"
    cash = Account.create!(name: "Wallet", account_type: "checking", currency: "USD")
    get assets_path(on: "2026-10-21")
    assert_select "#account-card-#{cash.id}", text: /Unknown/
    assert_select "#account-card-#{@other.id}", text: /Carried forward from/, count: 0
    get assets_path(on: "2026-10-21", edit: "#{@other.id}-#{@qqq.id}")
    assert_select "[data-section=observation-status]", text: /Carried forward from 2026-03-15/
    state, = PositionObservation.state_on({ account: @other, security: @qqq }, Date.new(2026, 10, 21))
    assert_equal :carried_forward, state
  end

  test "a corporate action changes quantity from its effective date" do
    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: "2026-06-01",
      gesture: "add", quantity: "100", cost_basis: "10", reason: "corporate_action", historical_ack: "1"
    }
    current = PositionObservation.current_on({ account: @account, security: @voo }, Date.new(2026, 7, 1))

    assert_equal 100, current.quantity
    assert_equal "corporate_action", current.reason
  end

  test "the holding editor names the pending save, shows the price field, and offers a distinct verify action" do
    edit = "#{@account.id}-#{@voo.id}"
    get assets_path(on: "2026-03-15", edit:)
    assert_includes response.body, "Pending save: No changes"
    assert_includes response.body, "Market price per share"
    assert_includes response.body, "No price recorded for 2026-03-15"
    assert_includes response.body, "Prepopulated from"
    assert_select "button[name=gesture][value=verify]", text: "Verify holding"
    assert_includes response.body, "VOO"
    assert_includes response.body, "Brokerage"
    assert_includes response.body, "Observation date"
    assert_includes response.body, "Last verified"
    assert_select "[role=dialog]"
    assert_select ".max-lg\\:fixed"

    get assets_path(on: "2026-03-15", edit:, quantity: "99")
    assert_includes response.body, "Pending save: Edit observation"

    get assets_path(on: "2026-10-21", edit:)
    assert_includes response.body, "Pending save: New observation"
    assert_select "[data-section=observation-status]", text: /Carried forward from 2026-03-15/
    assert_select "[data-controller~='reveal-panel'][data-reveal-panel-focus-value=holding-editor-title]"
    assert_select "#account-card-#{@account.id}", text: /Carried forward from/, count: 0
  end

  test "the holding editor prefills the exact-date price and shows when none is saved" do
    MarketPrice.upsert_effective!(security: @voo, amount: 401, market_on: Date.new(2026, 3, 15),
                                  currency: "USD", source: "manual", entered_by: @user)
    edit = "#{@account.id}-#{@voo.id}"

    get assets_path(on: "2026-03-15", edit:)

    assert_select "input[name=price][value=?]", "401.0"
    assert_includes response.body, "Saved price for 2026-03-15"

    get assets_path(on: "2026-03-20", edit:)
    assert_includes response.body, "No price recorded for 2026-03-20"
  end

  test "the editor distinguishes the requested date from the effective price date" do
    MarketPrice.upsert_effective!(security: @voo, amount: 401, market_on: Date.new(2026, 3, 15),
                                  currency: "USD", source: "manual", entered_by: @user)
    edit = "#{@account.id}-#{@voo.id}"

    get assets_path(on: "2026-03-20", edit:)

    assert_select "input[name=observed_on][value=?]", "2026-03-20"
    assert_includes response.body, "No price recorded for 2026-03-20"
    assert_includes response.body, "from the price dated 2026-03-15"
  end

  test "a backdated save is stored on the selected date and cancel does not write" do
    before = PositionObservation.count
    get assets_path(on: "2026-10-21", edit: "#{@account.id}-#{@voo.id}")
    assert_includes response.body, "Cancel"
    get assets_path(on: "2026-10-21")
    assert_equal before, PositionObservation.count

    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: "2026-01-15",
      gesture: "verify", quantity: "4", cost_basis: "10", historical_ack: "1"
    }
    stored = PositionObservation.kept.find_by!(account: @account, security: @voo, observed_on: Date.new(2026, 1, 15))
    assert_equal 4, stored.quantity
    state, = PositionObservation.state_on({ account: @other, security: @qqq }, Date.new(2026, 1, 15))
    assert_equal :unknown, state
  end

  test "an invalid holding save keeps the entered cost basis and does not create a row" do
    edit = "#{@account.id}-#{@voo.id}"
    before = PositionObservation.count
    params = {
      account_id: @account.id, security_id: @voo.id, edit:, observed_on: "2026-10-21",
      gesture: "verify", quantity: "", cost_basis: "15"
    }
    post holding_positions_path, params: params
    assert_response :unprocessable_entity
    assert_select "input[name=cost_basis][value=?]", "15"
    assert_select "input[name=quantity][aria-invalid=true][aria-describedby=editor-quantity-error]"
    assert_select "#editor-quantity-error", text: /blank/
    assert_select "button[data-turbo-submits-with=?]", "Saving…"
    assert_equal before, PositionObservation.count

    post holding_positions_path, params: params
    assert_response :unprocessable_entity
    assert_equal before, PositionObservation.count
  end

  test "assets hides maintenance forms and each maintenance choice shows one form" do
    get assets_path
    assert_select "form[action=?]", securities_path, count: 0
    assert_select "form[action=?]", market_prices_path, count: 0
    assert_select "button", text: "Save corporate action", count: 0
    cash = Account.create!(name: "Cash", account_type: "checking", currency: "USD")
    AccountObservation.revise_current!({ account: cash }, observed_on: Date.current, updated_by: @user, amount: 25)
    get assets_path
    assert_select "[data-section=reporting-date]"
    assert_select "[data-section=accounts]"
    assert_select "[data-section=summary]", count: 0
    assert_select "form[action=?]", securities_path, count: 0
    assert_operator response.body.index('data-section="reporting-date"'), :<, response.body.index('data-section="accounts"')
    assert_select "#account-card-#{@account.id} a.ui-link", text: "VOO"
    assert_select "#account-card-#{cash.id}", text: /\$25\.00/
    assert_select "#account-card-#{cash.id} a.ui-button-quiet", text: "Update balance"
    assert_select "#account-card-#{cash.id} a", text: "Add holding", count: 0
    assert_select "#account-card-#{@account.id} a.ui-button-quiet", text: "Add Holding"
    assert_select "#account-card-#{@account.id} #add-holding-#{@account.id}.ui-button", count: 0
    assert_select "#account-card-#{@account.id} a.ui-button-quiet", text: "Record Cash"

    get asset_maintenance_path(form: "security")
    assert_select "input[name=?]", "security[ticker]"
    assert_select "input[name=?]", "market_price[amount]", count: 0
    assert_select "button", text: "Save corporate action", count: 0

    get asset_maintenance_path(form: "price")
    assert_select "input[name=?]", "market_price[amount]"
    assert_select "input[name=?]", "security[ticker]", count: 0

    get asset_maintenance_path(form: "action")
    assert_select "button", text: "Save corporate action"
    assert_select "input[name=?]", "security[ticker]", count: 0

    assert_difference -> { Security.count }, 1 do
      post securities_path, params: { security: { ticker: "IVV", identifier: "IVV", currency: "USD" } }
    end
    assert_difference -> { MarketPrice.count }, 1 do
      post market_prices_path, params: { market_price: { security_id: @voo.id, amount: "12.5", currency: "USD", market_on: "2026-10-01" } }
    end
  end

  test "chart json keeps august 28 and september 4 and the monthly point uses the later date" do
    PositionObservation.revise_current!({ account: @account, security: @voo }, observed_on: Date.new(2021, 8, 28), updated_by: @user, quantity: 4, cost_basis: 1)
    PositionObservation.revise_current!({ account: @account, security: @voo }, observed_on: Date.new(2021, 9, 4), updated_by: @user, quantity: 6, cost_basis: 1)
    get chart_observations_path(account_id: @account.id, security_id: @voo.id)
    body = JSON.parse(response.body)

    assert_includes body["detailed"].map { |point| point["date"] }, "2021-08-28"
    assert_includes body["detailed"].map { |point| point["date"] }, "2021-09-04"
  end

  test "a price-only save updates the shared price without a holding observation" do
    before = PositionObservation.count

    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: "2026-03-15",
      gesture: "save", quantity: "50", cost_basis: "10", price: "401", historical_ack: "1"
    }

    assert_redirected_to assets_path(on: "2026-03-15")
    assert_equal before, PositionObservation.count
    assert_equal BigDecimal("401"), MarketPrice.effective_on(@voo, Date.new(2026, 3, 15)).amount
  end

  test "an unchanged save records nothing and explains it" do
    before = PositionObservation.count

    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: "2026-03-15",
      gesture: "save", quantity: "50", cost_basis: "10", historical_ack: "1"
    }
    follow_redirect!

    assert_equal before, PositionObservation.count
    assert_includes response.body, "Nothing changed"
  end

  test "a past-date save without the acknowledgment is rejected in place" do
    before = PositionObservation.count

    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: "2026-01-15",
      gesture: "save", quantity: "4", cost_basis: "10"
    }

    assert_response :unprocessable_entity
    assert_equal before, PositionObservation.count
    assert_includes response.body, "acknowledged"
  end

  test "a future-dated holding save is rejected" do
    post holding_positions_path, params: {
      account_id: @account.id, security_id: @voo.id, observed_on: (Date.current + 5).iso8601,
      gesture: "save", quantity: "4", cost_basis: "10"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "future"
  end
end
