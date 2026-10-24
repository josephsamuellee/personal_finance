require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "a protected route requires login" do
    create_user
    get root_path

    assert_redirected_to new_session_path
  end

  test "two users can authenticate and share an expense" do
    first = create_user
    sign_in_as(first)
    category = ExpenseCategory.create!(name: "Groceries")
    post expenses_path, params: { expense: { amount: "12.5", expense_category_id: category.id, spent_on: Date.current, kind: "spending" } }
    expense = Expense.last
    delete session_path

    second = create_user(email: "bea@example.com")
    sign_in_as(second)
    get expense_path(expense)

    assert_response :success
    patch expense_path(expense), params: { expense: { merchant: "Market" } }
    assert_equal second, expense.reload.updated_by
  end

  test "the first user can be created only while none exist and a signed-in user can add another" do
    get new_user_path
    assert_response :success
    post users_path, params: { user: { email_address: "ada@example.com", password: "password-password", password_confirmation: "password-password" } }
    assert_redirected_to root_path

    delete session_path
    get new_user_path
    assert_redirected_to new_session_path

    sign_in_as(User.find_by!(email_address: "ada@example.com"))
    post users_path, params: { user: { email_address: "bea@example.com", password: "password-password", password_confirmation: "password-password" } }
    assert_equal 2, User.count
    get root_path
    assert_includes response.body, "ada@example.com"
  end
end
