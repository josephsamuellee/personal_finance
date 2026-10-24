require "test_helper"

class BackupTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "a backup contains the database snapshot and a receipt and restore returns both" do
    user = create_user
    category = ExpenseCategory.create!(name: "Groceries")
    expense = Expense.create!(kind: "spending", amount: 9, spent_on: Date.new(2026, 10, 2), expense_category: category, created_by: user, updated_by: user)
    expense.receipts.attach(io: StringIO.new("%PDF-1.4 receipt"), filename: "receipt.pdf", content_type: "application/pdf")
    root = Rails.root.join("tmp/backup-test-#{SecureRandom.hex(4)}")
    ENV["BACKUP_ROOT"] = root.to_s
    ENV["BACKUP_RETENTION"] = "30"
    Rails.application.load_tasks
    Rake::Task["household:backup"].reenable
    Rake::Task["household:backup"].invoke
    destination = Pathname(root).children.select(&:directory?).max_by(&:basename)

    assert File.exist?(destination.join("database.sqlite3"))
    assert Dir.glob(destination.join("storage/**/*")).any? { |path| File.file?(path) }

    expense.receipts.purge
    expense.destroy!
    ENV["BACKUP_DIR"] = destination.to_s
    Rake::Task["household:restore"].reenable
    Rake::Task["household:restore"].invoke

    restored = Expense.find_by(amount: 9)
    assert restored
    assert restored.receipts.attached?
  ensure
    FileUtils.rm_rf(root) if defined?(root) && root
    connection = ActiveRecord::Base.connection
    connection.disable_referential_integrity do
      connection.tables.each do |table|
        next if %w[schema_migrations ar_internal_metadata].include?(table)

        connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
      end
    end
  end
end
