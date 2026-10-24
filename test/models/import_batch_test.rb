require "test_helper"

class ImportBatchTest < ActiveSupport::TestCase
  test "a holdings batch can be stored without expenses" do
    user = create_user
    account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    batch = ImportBatch.create!(user:, account:, kind: "holdings", status: "imported")

    assert_equal "holdings", batch.kind
    assert_equal account, batch.account
    assert_equal 0, batch.expenses.count
  end

  test "expense batches keep the expenses kind by default" do
    user = create_user
    batch = ImportBatch.create!(user:, status: "imported")

    assert_equal "expenses", batch.kind
  end
end
