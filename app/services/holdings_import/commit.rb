module HoldingsImport
  class Commit
    Result = Struct.new(:status, :batch, :planned, keyword_init: true)

    def initialize(account:, user:, captured_on:, rows:, authorized_price_keys:, historical_ack:, fingerprint:)
      @account = account
      @user = user
      @captured_on = captured_on
      @rows = rows
      @authorized_price_keys = authorized_price_keys
      @historical_ack = historical_ack
      @fingerprint = fingerprint
    end

    def call
      planner = Planner.new(account: @account, captured_on: @captured_on, rows: @rows,
                            authorized_price_keys: @authorized_price_keys)
      planned = planner.plan
      return Result.new(status: :invalid, planned:) unless planned.all?(&:valid?)
      return Result.new(status: :stale, planned:) if planner.fingerprint(planned) != @fingerprint

      if planned.any? { |row| row.observed_on < Date.current } && @historical_ack.to_s != "1"
        return Result.new(status: :historical, planned:)
      end

      batch = nil
      ActiveRecord::Base.transaction do
        batch = ImportBatch.create!(user: @user, kind: "holdings", account: @account, status: "imported")
        planned.reject(&:no_op?).each { |row| save_row!(row) }
      end
      Result.new(status: :ok, batch:, planned:)
    end

    private
      def save_row!(row)
        if row.security && row.note.present? && row.note != row.security.note.to_s
          row.security.update!(note: row.note)
        end

        form = HoldingForm.new(
          account: @account, security: row.security, user: @user,
          gesture: row.security ? "save" : "create",
          ticker: row.ticker, currency: row.currency, note: row.note.presence,
          observed_on: row.observed_on.iso8601, quantity: row.quantity, cost_basis: row.cost_basis,
          price: row.price, historical_ack: "1"
        )
        raise ActiveRecord::RecordInvalid, form unless form.valid?

        form.save!
      end
  end
end
