require "test_helper"

class ShellTest < ActionDispatch::IntegrationTest
  test "navigation shows the primary destinations and quick expense" do
    get new_session_path

    assert_response :success
    assert_includes response.body, "Home"
    assert_includes response.body, "Expenses"
    assert_includes response.body, "Assets"
    assert_includes response.body, "Review"
    assert_includes response.body, "Quick Expense"
    assert_includes response.body, "overflow-x-hidden"
    assert_includes response.body, "viewport-fit=cover"
    assert_includes response.body, "max-w-7xl"
    assert_select "body.overflow-x-hidden"
    assert_includes response.body, "safe-area-inset-bottom"
    assert_select "a[aria-current=page]", count: 0
    assert_select "nav[aria-label=Primary].lg\\:hidden" do
      %w[Home Expenses Assets Review].each do |label|
        assert_select "a.ui-nav.min-h-11.min-w-11", text: label
      end
    end
    assert_select "aside.lg\\:flex" do
      %w[Home Expenses Assets Review].each do |label|
        assert_select "a.ui-nav.min-h-11.min-w-11", text: label
      end
    end
    assert_select "input.ui-field"
    assert_select "input.ui-button"
  end

  test "primary navigation follows the route that is open" do
    user = create_user
    sign_in_as(user)
    expense = Expense.create!(
      kind: "spending", amount: 6, spent_on: Date.new(2026, 10, 2),
      expense_category: ExpenseCategory.create!(name: "Coffee"), created_by: user, updated_by: user
    )

    get root_path
    assert_current_destination "Home"
    get assets_path
    assert_current_destination "Assets"
    get accounts_path
    assert_current_destination "Assets"
    get expense_path(expense)
    assert_current_destination "Expenses"
    get quick_expense_path
    assert_current_destination "Expenses"
    get reviews_path
    assert_current_destination "Review"
  end

  test "manifest is served" do
    get "/manifest.json"

    assert_response :success
    assert_includes response.body, "Personal Finance"
    assert_includes response.body, "/android-chrome-192x192.png"
    assert_includes response.body, "/android-chrome-512x512.png"
  end

  test "service worker does not cache writes or register background sync" do
    get "/service-worker.js"

    assert_response :success
    assert_no_match(/sync\.register|SyncManager|backgroundsync/i, response.body)
    assert_no_match(/caches\.put/, response.body)
  end

  test "an unapproved host is rejected" do
    get root_path, headers: { "HOST" => "evil.example" }

    assert_response :forbidden
  end

  test "serverlite is an allowed host" do
    get new_session_path, headers: { "HOST" => "serverlite" }

    assert_response :success
  end

  test "a state-changing request without a csrf token is rejected" do
    ActionController::Base.allow_forgery_protection = true
    post session_path, params: { email_address: "ada@example.com", password: "password-password" }

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  private
    def assert_current_destination(label)
      assert_select "nav[aria-label=Primary] a[aria-current=page]", text: label
      assert_select "aside a[aria-current=page]", text: label
      assert_select "a[aria-current=page]", count: 2
    end
end
