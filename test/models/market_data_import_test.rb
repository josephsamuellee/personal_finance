require "test_helper"

class MarketDataImportTest < ActiveSupport::TestCase
  ROWS = {
    "2026-01-02" => "390.5",
    "2026-01-03" => "391.0",
    "2026-01-05" => "392.25"
  }.freeze

  setup do
    @user = create_user
    @security = Security.create!(ticker: "VOO", currency: "USD")
  end

  def import_with(rows: ROWS, replace: false, from: Date.new(2026, 1, 1), to: Date.new(2026, 1, 31))
    MarketData::Import.new(adapter: FakeHistoryAdapter.new(rows)).call(@security, from:, to:, replace:)
  end

  test "an import caches prices with metadata and invents no non-trading prices" do
    result = import_with

    assert_equal 3, result.imported
    assert_equal 3, MarketPrice.where(security: @security).count

    price = MarketPrice.effective_on(@security, Date.new(2026, 1, 5))
    assert_equal BigDecimal("392.25"), price.amount
    assert_equal "Fake", price.source
    assert_equal "raw", price.adjustment_convention
    assert_not_nil price.retrieved_at

    # January 4 2026 is a Sunday with no provider row: nothing invented.
    assert_nil MarketPrice.effective_on(@security, Date.new(2026, 1, 4))
  end

  test "a later import of the same range is deterministic and does not accumulate" do
    import_with
    first = MarketPrice.where(security: @security).order(:market_on).pluck(:amount, :market_on)

    import_with
    second = MarketPrice.where(security: @security).order(:market_on).pluck(:amount, :market_on)

    assert_equal first, second
    assert_equal 3, MarketPrice.where(security: @security).count
  end

  test "imports preserve manual prices unless replacement is explicitly chosen" do
    MarketPrice.upsert_effective!(security: @security, amount: 1, market_on: Date.new(2026, 1, 5),
                                  currency: "USD", source: "manual", entered_by: @user)

    result = import_with

    assert_equal 1, result.kept_manual
    assert_equal 2, result.imported
    assert_equal BigDecimal("1"), MarketPrice.effective_on(@security, Date.new(2026, 1, 5)).amount

    replaced = import_with(replace: true)

    assert_equal 0, replaced.kept_manual
    price = MarketPrice.effective_on(@security, Date.new(2026, 1, 5))
    assert_equal BigDecimal("392.25"), price.amount
    assert_equal "Fake", price.source
  end

  test "an overlapping import is deterministic across ranges" do
    import_with(from: Date.new(2026, 1, 1), to: Date.new(2026, 1, 3))
    import_with(from: Date.new(2026, 1, 3), to: Date.new(2026, 1, 31))

    assert_equal 3, MarketPrice.where(security: @security).count
    assert_equal BigDecimal("391.0"), MarketPrice.effective_on(@security, Date.new(2026, 1, 3)).amount
  end

  test "a provider failure keeps previously cached prices" do
    import_with

    result = MarketData::Import.new(adapter: BoomHistoryAdapter.new)
                               .call(@security, from: Date.new(2026, 2, 1), to: Date.new(2026, 2, 28))

    assert_equal @security, result.failed
    assert_equal 3, MarketPrice.where(security: @security).count
  end

  class FakeHistoryAdapter < MarketData::Adapter
    NAME = "Fake"

    def initialize(rows)
      @rows = rows
    end

    def history(_security, from:, to:)
      @rows.filter_map do |date, amount|
        market_on = Date.parse(date)
        (from..to).cover?(market_on) ? { amount: BigDecimal(amount), market_on:, currency: "USD", adjustment_convention: "raw" } : nil
      end
    end
  end

  class BoomHistoryAdapter < MarketData::Adapter
    NAME = "Boom"

    def history(_security, from:, to:)
      raise MarketData::ProviderError, "unavailable"
    end
  end
end
