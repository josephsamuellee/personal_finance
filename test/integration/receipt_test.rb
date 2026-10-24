require "test_helper"

class ReceiptTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @category = ExpenseCategory.create!(name: "Groceries")
  end

  test "an expense saves without a receipt and an authenticated user can view an image and a PDF" do
    expense = Expense.create!(
      kind: "spending", amount: 4, spent_on: Date.new(2026, 10, 2),
      expense_category: @category, created_by: @user, updated_by: @user
    )
    assert_not expense.receipts.attached?

    expense.receipts.attach(io: StringIO.new("png-bytes"), filename: "receipt.png", content_type: "image/png")
    expense.receipts.attach(io: StringIO.new("%PDF-1.4"), filename: "receipt.pdf", content_type: "application/pdf")
    sign_in_as(@user)

    expense.receipts.each do |receipt|
      get rails_blob_path(receipt, disposition: "inline")
      assert_response :redirect
      follow_redirect!
      assert_response :success
    end
  end

  test "an unauthenticated attachment request is refused" do
    expense = Expense.create!(
      kind: "spending", amount: 4, spent_on: Date.new(2026, 10, 2),
      expense_category: @category, created_by: @user, updated_by: @user
    )
    expense.receipts.attach(io: StringIO.new("%PDF-1.4"), filename: "receipt.pdf", content_type: "application/pdf")

    get rails_blob_path(expense.receipts.first, disposition: "inline")

    assert_redirected_to new_session_path
  end
end
