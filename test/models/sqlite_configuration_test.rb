require "test_helper"

class SqliteConfigurationTest < ActiveSupport::TestCase
  test "journal mode is wal" do
    mode = ActiveRecord::Base.connection.select_value("PRAGMA journal_mode")

    assert_equal "wal", mode
  end

  test "busy timeout is configured" do
    timeout = ActiveRecord::Base.connection.select_value("PRAGMA busy_timeout")

    assert_operator timeout.to_i, :>=, 5000
  end
end
