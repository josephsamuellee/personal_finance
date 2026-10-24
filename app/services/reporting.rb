module Reporting
  CALCULATION_VERSION = "household-finance-1"

  Component = Struct.new(
    :key, :label, :side, :amount, :state, :liquid, :group, :source_date,
    :price_date, :price_source, :record_type, :record_id, :unknown, :unrealized_gain,
    keyword_init: true
  ) do
    def carried_forward?
      state == :carried_forward
    end
  end
end
