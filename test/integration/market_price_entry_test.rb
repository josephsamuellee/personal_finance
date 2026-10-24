require "test_helper"

class MarketPriceEntryTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
    @security = Security.create!(ticker: "VOO", currency: "USD")
  end

  test "saving a manual price for an existing date updates the effective price" do
    post market_prices_path, params: { market_price: { security_id: @security.id, amount: "20", currency: "USD", market_on: "2026-10-01" } }
    assert_redirected_to asset_maintenance_path(form: "price")

    assert_no_difference -> { MarketPrice.count } do
      post market_prices_path, params: { market_price: { security_id: @security.id, amount: "21", currency: "USD", market_on: "2026-10-01" } }
    end

    assert_equal 1, MarketPrice.where(security: @security).count
    assert_equal BigDecimal("21"), MarketPrice.effective_on(@security, Date.new(2026, 10, 1)).amount
  end

  test "an invalid manual price keeps the entered amount and explains the error" do
    post market_prices_path, params: { market_price: { security_id: @security.id, amount: "abc", currency: "USD", market_on: "2026-10-01" } }

    assert_response :unprocessable_entity
    assert_select "ul[role=alert]"
    assert_equal 0, MarketPrice.count
  end
end
