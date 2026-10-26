require "csv"

class HoldingCsv
  HEADERS = %w[ticker note currency observation_date quantity cost_basis price_per_share].freeze
  BULK_HEADERS = %w[account_id account_name ticker note currency observation_date quantity cost_basis price_per_share last_price].freeze
  FORMULA_START = /\A[=+\-@]/
  MAX_BYTES = 1_048_576
  MAX_ROWS = 500

  Row = Struct.new(
    :line, :account, :ticker, :note, :currency, :observation_date, :quantity, :cost_basis, :price_per_share, :errors, :warnings,
    keyword_init: true
  ) do
    def initialize(**)
      super
      self.warnings ||= []
    end

    def valid?
      errors.empty?
    end
  end

  Result = Struct.new(:rows, :file_errors, keyword_init: true) do
    def valid?
      file_errors.empty? && rows.all?(&:valid?)
    end
  end

  def self.template
    CSV.generate { |csv| csv << HEADERS }
  end

  def self.parse(io, captured_on:, account: nil)
    read_table(io, HEADERS) do |table|
      rows = table.each_with_index.map { |record, index| build_row(record, index + 2, captured_on).tap { |row| row.account = account } }
      mark_duplicates(rows)
      Result.new(rows:, file_errors: [])
    end
  end

  def self.parse_bulk(io, captured_on:)
    read_table(io, BULK_HEADERS) do |table|
      accounts = Account.where(id: table.map { |record| record["account_id"].to_s.strip }.grep(/\A\d+\z/)).index_by(&:id)
      rows = table.each_with_index.map do |record, index|
        build_row(record, index + 2, captured_on).tap do |row|
          row.note = from_spreadsheet_text(row.note)
          assign_account(row, record, accounts)
        end
      end
      mark_duplicates(rows)
      mark_mixed_dates(rows)
      Result.new(rows:, file_errors: [])
    end
  end

  # A leading quote stops spreadsheets from running text as a formula; the bulk export adds it and parsing removes it.
  def self.to_spreadsheet_text(value)
    value.to_s.match?(FORMULA_START) ? "'#{value}" : value
  end

  def self.from_spreadsheet_text(value)
    value.to_s.start_with?("'") && value.to_s[1..].match?(FORMULA_START) ? value.to_s[1..] : value
  end

  def self.read_table(io, headers)
    text = read_utf8(io)
    return Result.new(rows: [], file_errors: [ "The file is larger than 1 MB." ]) if text.bytesize > MAX_BYTES

    table = CSV.parse(text, headers: true)
    return Result.new(rows: [], file_errors: [ "The CSV headers must be #{headers.join(', ')}." ]) unless table.headers == headers
    return Result.new(rows: [], file_errors: [ "The CSV has more than #{MAX_ROWS} data rows." ]) if table.size > MAX_ROWS

    yield table
  rescue CSV::MalformedCSVError, ArgumentError
    Result.new(rows: [], file_errors: [ "The CSV could not be parsed." ])
  end

  def self.assign_account(row, record, accounts)
    id_text = record["account_id"].to_s.strip
    account = accounts[id_text.to_i] if id_text.match?(/\A\d+\z/)

    if id_text.blank?
      row.errors << "account_id is required"
    elsif account.nil?
      row.errors << "Account #{id_text} was not found"
    elsif account.archived_at
      row.errors << "Account #{id_text} (#{account.name}) is archived"
    elsif !account.brokerage?
      row.errors << "Account #{id_text} (#{account.name}) is not a brokerage account"
    else
      row.account = account
      name = from_spreadsheet_text(record["account_name"].to_s.strip)
      if name != account.name
        row.warnings << "Account #{account.id} is \"#{account.name}\" but the CSV says \"#{name}\"; this row will save to #{account.name}"
      end
    end
  end

  def self.build_row(record, line, captured_on)
    errors = []
    ticker = record["ticker"].to_s.strip.upcase
    errors << "Ticker is required" if ticker.blank?

    quantity = parse_number(record["quantity"])
    if record["quantity"].to_s.strip.blank?
      errors << "Quantity is required"
    elsif quantity.nil?
      errors << "Quantity is invalid"
    elsif quantity.negative?
      errors << "Quantity must be zero or positive"
    end

    cost_basis = parse_number(record["cost_basis"])
    if record["cost_basis"].to_s.strip.blank?
      errors << "Cost basis is required"
    elsif cost_basis.nil?
      errors << "Cost basis is invalid"
    elsif cost_basis.negative?
      errors << "Cost basis must be zero or positive"
    end

    price = record["price_per_share"].to_s.strip
    price_value = if price.blank?
      nil
    else
      parsed = parse_number(price)
      errors << "Price is invalid" if parsed.nil? || parsed <= 0
      parsed
    end

    date_text = record["observation_date"].to_s.strip
    observed_on = if date_text.blank?
      captured_on
    else
      parse_iso_date(date_text).tap { |date| errors << "Observation date must be YYYY-MM-DD" if date.nil? }
    end
    errors << "Observation date cannot be in the future" if observed_on && observed_on > Date.current

    currency = record["currency"].to_s.strip.upcase
    currency = "USD" if currency.blank?
    errors << "Currency must be a 3-letter code" unless currency.match?(/\A[A-Z]{3}\z/)

    Row.new(
      line:, ticker:, note: record["note"].to_s, currency:, observation_date: observed_on,
      quantity:, cost_basis:, price_per_share: price_value, errors:
    )
  end

  def self.mark_duplicates(rows)
    groups = rows.group_by { |row| [ row.account&.id, row.ticker, row.observation_date ] }
    groups.each_value do |group|
      next if group.size < 2 || group.any? { |row| row.ticker.blank? || row.observation_date.nil? }

      lines = group.map(&:line)
      group.each { |row| row.errors << "Duplicate of rows #{lines.join(', ')} for this security and date" }
    end
  end

  def self.mark_mixed_dates(rows)
    by_date = rows.select(&:observation_date).group_by(&:observation_date)
    return if by_date.size < 2

    summary = by_date.sort.map do |date, group|
      lines = group.map(&:line)
      "#{date.iso8601} (#{lines.one? ? 'row' : 'rows'} #{lines.join(', ')})"
    end
    message = "The file must use one observation date but has #{summary.join(', ')}"
    rows.each { |row| row.errors << message }
  end

  def self.parse_iso_date(value)
    Date.iso8601(value)
  rescue Date::Error
    nil
  end

  def self.parse_number(value)
    return if value.nil?

    BigDecimal(value.to_s.strip.delete(",").delete("$"))
  rescue ArgumentError
    nil
  end

  def self.read_utf8(io)
    raw = io.respond_to?(:read) ? io.read : io.to_s
    text = +raw.to_s
    text.force_encoding(Encoding::UTF_8)
    raise ArgumentError, "Invalid UTF-8" unless text.valid_encoding?

    text.delete_prefix("\uFEFF")
  end
end
