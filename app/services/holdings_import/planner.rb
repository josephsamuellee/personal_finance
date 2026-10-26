module HoldingsImport
  PlanRow = Struct.new(
    :line, :account, :ticker, :security, :note, :previous_note, :currency, :observed_on,
    :quantity, :cost_basis, :price, :saved_price, :outcomes, :errors, :warnings, :price_key,
    keyword_init: true
  ) do
    def valid?
      errors.empty?
    end

    def no_op?
      outcomes == [ "no-op" ]
    end

    def price_conflict?
      outcomes.include?("price change")
    end
  end

  class Planner
    def initialize(captured_on:, rows:, authorized_price_keys: [])
      @captured_on = captured_on
      @rows = rows
      @authorized_price_keys = authorized_price_keys.map(&:to_s)
    end

    def plan
      @rows.map { |row| plan_row(row) }
    end

    def fingerprint(planned = plan)
      planned.map { |row|
        [
          row.line, row.account&.id, row.ticker, row.security&.id, row.observed_on&.iso8601,
          row.quantity&.to_s, row.cost_basis&.to_s, row.price&.to_s, row.saved_price&.to_s, row.note
        ]
      }.to_json
    end

    private
      def plan_row(row)
        planned = PlanRow.new(
          line: row.line, account: row.account, ticker: row.ticker, note: row.note, currency: row.currency,
          observed_on: row.observation_date, quantity: row.quantity, cost_basis: row.cost_basis,
          price: row.price_per_share, outcomes: [], errors: row.errors.dup, warnings: row.warnings.dup
        )
        return planned unless planned.errors.empty?

        matches = Security.where(ticker: row.ticker).to_a
        if matches.size > 1
          planned.errors << "Ticker #{row.ticker} matches more than one security"
          return planned
        end

        planned.security = matches.first
        planned.previous_note = planned.security&.note
        planned.price_key = "#{row.ticker}:#{row.observation_date}"
        saved = planned.security && MarketPrice.effective_on(planned.security, row.observation_date)
        planned.saved_price = saved&.amount

        if row.price_per_share.nil?
          if saved
            planned.price = saved.amount
          else
            planned.errors << "A market price for this date is required"
            return planned
          end
        elsif saved && saved.amount != row.price_per_share
          planned.outcomes << "price change"
          unless @authorized_price_keys.include?(planned.price_key)
            planned.errors << "Confirm replacing the saved price of #{saved.amount} with #{row.price_per_share}"
          end
        end

        observation = if planned.security
          PositionObservation.current_on({ account_id: row.account.id, security_id: planned.security.id }, row.observation_date)
        end
        on_date = if planned.security
          PositionObservation.kept.where(account: row.account, security: planned.security, observed_on: row.observation_date)
                             .order(sequence: :desc).first
        end

        note_changes = row.note.present? && row.note != planned.previous_note.to_s
        planned.outcomes << "shared note change" if note_changes

        if planned.security.nil?
          planned.outcomes << "new security"
          planned.outcomes << "new holding"
        elsif observation.nil?
          planned.outcomes << "new holding"
        elsif same_number?(observation.quantity, row.quantity) && same_number?(observation.cost_basis, row.cost_basis) &&
              (row.price_per_share.nil? || same_number?(planned.saved_price, planned.price)) && !note_changes &&
              !planned.price_conflict?
          planned.outcomes << "no-op" if planned.outcomes.empty?
        elsif on_date
          planned.outcomes << "updated observation" unless planned.outcomes.include?("updated observation")
        else
          planned.outcomes << "updated observation"
        end

        planned.outcomes.uniq!
        planned
      end

      def same_number?(left, right)
        return false if left.nil? || right.nil?

        BigDecimal(left.to_s) == BigDecimal(right.to_s)
      rescue ArgumentError
        false
      end
  end
end
