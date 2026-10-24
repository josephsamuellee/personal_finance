require "test_helper"

class AddHoldingWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
    @brokerage = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
  end

  test "the add holding form applies the defaults: today, USD, and required fields" do
    get new_account_holding_path(@brokerage)

    assert_select "input[name=observed_on][value=?]", Date.current.iso8601
    assert_select "input[name=currency][value=?]", "USD"
    assert_select "select[name=security_id] option", text: "Choose an existing security"
    assert_select "textarea[name=note]"
    assert_select "input[name=quantity][required]"
    assert_select "input[name=cost_basis][required]"
    assert_select "button", text: "Save holding"
  end

  test "an existing security with a saved price is reused with the price prefilled" do
    voo = Security.create!(ticker: "VOO", currency: "USD", note: "core fund")
    MarketPrice.upsert_effective!(security: voo, amount: 400, market_on: Date.current,
                                  currency: "USD", source: "manual", entered_by: @user)

    get new_account_holding_path(@brokerage, security_id: voo.id, observed_on: Date.current.iso8601)

    assert_select "select[name=security_id] option[selected]", text: "VOO"
    assert_select "input[name=price][value=?]", "400.0"
    assert_includes response.body, "Saved price for #{Date.current}"

    assert_no_difference -> { Security.count } do
      assert_difference -> { PositionObservation.count }, 1 do
        post account_holdings_path(@brokerage), params: {
          security_id: voo.id, observed_on: Date.current.iso8601,
          quantity: "10", cost_basis: "4000", price: "401"
        }
      end
    end

    assert_redirected_to assets_path(on: Date.current.iso8601)
    assert_equal BigDecimal("401"), MarketPrice.effective_on(voo, Date.current).amount
    assert_equal 10, PositionObservation.current_on({ account_id: @brokerage.id, security_id: voo.id }, Date.current).quantity
  end

  test "a new ticker creates the security and holding through one save" do
    assert_difference -> { Security.count }, 1 do
      post account_holdings_path(@brokerage), params: {
        ticker: "xyz", note: "speculative", currency: "USD",
        observed_on: Date.current.iso8601, quantity: "5", cost_basis: "100", price: "20"
      }
    end

    security = Security.find_by!(ticker: "XYZ")
    assert_equal "USD", security.currency
    assert_equal "speculative", security.note
    assert_nil security.identifier
    row = PositionObservation.current_on({ account_id: @brokerage.id, security_id: security.id }, Date.current)
    assert_equal 5, row.quantity
    assert_equal 20, MarketPrice.effective_on(security, Date.current).amount
  end

  test "a missing price blocks creation with an explanation and no partial records" do
    other = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")

    assert_no_difference -> { PositionObservation.count } do
      assert_no_difference -> { Security.count } do
        post account_holdings_path(other), params: {
          ticker: "QQQ", currency: "USD", observed_on: Date.current.iso8601,
          quantity: "5", cost_basis: "100", price: ""
        }
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "A market price for this date is required"
    assert_nil Security.find_by(ticker: "QQQ")
    assert_select "input[name=quantity][value=?]", "5"
    assert_select "input[name=cost_basis][value=?]", "100"
  end

  test "a save without a security or ticker explains what is missing" do
    post account_holdings_path(@brokerage), params: {
      observed_on: Date.current.iso8601, quantity: "5", cost_basis: "100", price: "20"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Choose a security or enter a new ticker"
  end

  test "a failed combined save leaves no security, holding, or price behind" do
    assert_no_difference -> { Security.count } do
      post account_holdings_path(@brokerage), params: {
        ticker: "BAD", currency: "USD", observed_on: Date.current.iso8601,
        quantity: "abc", cost_basis: "100", price: "20"
      }
    end

    assert_response :unprocessable_entity
    assert_nil Security.find_by(ticker: "BAD")
    assert_equal 0, MarketPrice.count
  end
end
