require "csv"

class ExpenseCsv
  Row = Struct.new(:line, :spent_on, :amount, :category_name, :merchant, :notes, :kind, :errors, keyword_init: true) do
    def valid?
      errors.empty?
    end
  end

  def self.parse(io, mapping)
    text = io.respond_to?(:read) ? io.read : io.to_s
    csv = CSV.new(text, headers: true)
    csv.each_with_index.map do |record, index|
      build_row(record, index + 2, mapping)
    end
  end

  def self.build_row(record, line, mapping)
    errors = []
    spent_on = parse_date(record[mapping["date"]])
    amount = parse_amount(record[mapping["amount"]])
    category_name = record[mapping["category"]].to_s.strip
    kind = record[mapping["kind"]].to_s.strip.downcase.presence || "spending"
    errors << "Date is invalid" if spent_on.nil?
    errors << "Amount is invalid" if amount.nil? || amount.zero?
    errors << "Category is missing" if category_name.blank? && kind != "transfer"
    errors << "Transfers are not imported as expenses" if kind == "transfer"
    errors << "Kind is not an expense" unless %w[spending refund].include?(kind)

    Row.new(
      line:,
      spent_on:,
      amount:,
      category_name:,
      merchant: mapping["merchant"].present? ? record[mapping["merchant"]] : nil,
      notes: mapping["notes"].present? ? record[mapping["notes"]] : nil,
      kind:,
      errors:
    )
  end

  def self.parse_date(value)
    return if value.blank?

    text = value.to_s.strip
    begin
      Date.iso8601(text)
    rescue Date::Error
      begin
        Date.strptime(text, "%m/%d/%Y")
      rescue Date::Error
        nil
      end
    end
  end

  def self.parse_amount(value)
    return if value.blank?

    BigDecimal(value.to_s.delete(",").delete("$"))
  rescue ArgumentError
    nil
  end
end
