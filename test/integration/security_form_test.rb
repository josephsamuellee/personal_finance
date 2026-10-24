require "test_helper"

class SecurityFormTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
  end

  test "the security form asks only for ticker, optional note, and currency defaulting to USD" do
    get asset_maintenance_path(form: "security")

    assert_select "input[name=?]", "security[ticker]"
    assert_select "textarea[name=?]", "security[note]"
    assert_select "input[name=?][value=USD]", "security[currency]"
    assert_select "input[name=?]", "security[identifier]", count: 0

    assert_difference -> { Security.count }, 1 do
      post securities_path, params: { security: { ticker: "ivv", note: "core fund", currency: "USD" } }
    end

    security = Security.find_by!(ticker: "IVV")
    assert_equal "core fund", security.note
    assert_equal "USD", security.currency
    assert_nil security.identifier
  end

  test "a security save with a blank ticker shows the validation error in place" do
    assert_no_difference -> { Security.count } do
      post securities_path, params: { security: { ticker: "", currency: "USD" } }
    end

    assert_response :unprocessable_entity
    assert_select "ul[role=alert]", text: /blank/i
    assert_select "input[name=?]", "security[ticker]"
  end
end
