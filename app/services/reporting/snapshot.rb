module Reporting
  class Snapshot
    attr_reader :on

    def initialize(on:)
      @on = on
    end

    def components
      @components ||= account_components + position_components
    end

    def net_worth
      known_assets.sum { |component| component.amount.to_d } - known_debts.sum { |component| component.amount.to_d }
    end

    def liquid_assets
      components.select { |component| component.liquid && component.amount }.sum { |component| component.amount.to_d }
    end

    def incomplete?
      components.any?(&:unknown)
    end

    def estimated?
      components.any?(&:carried_forward?)
    end

    def quality_label
      labels = []
      labels << "Incomplete" if incomplete?
      labels << "Estimated" if estimated?
      labels << "Verified" if labels.empty?
      labels.join(" ")
    end

    def allocation
      %w[Cash Investments Property].index_with do |group|
        components.select { |component| component.group == group && component.amount && component.side == :asset }
                   .sum { |component| component.amount.to_d }
      end
    end

    def to_h
      {
        on: on.iso8601,
        net_worth: incomplete? ? nil : net_worth.to_s,
        liquid_assets: liquid_assets.to_s,
        quality: quality_label,
        components: components.map { |component|
          component.to_h.merge(
            amount: component.amount&.to_s,
            source_date: component.source_date&.iso8601,
            price_date: component.price_date&.iso8601
          )
        }
      }
    end

    def references
      {
        account_observation_ids: components.select { |component| component.record_type == "AccountObservation" }.map(&:record_id),
        position_observation_ids: components.select { |component| component.record_type == "PositionObservation" }.map(&:record_id),
        expense_ids: Expense.tracked.where(spent_on: on.all_month).pluck(:id)
      }
    end

    private
      def known_assets
        components.select { |component| component.side == :asset && component.amount }
      end

      def known_debts
        components.select { |component| component.side == :debt && component.amount }
      end

      def account_components
        Account.order(:name).flat_map do |account|
          row = AccountObservation.current_on({ account_id: account.id }, on)
          if row.nil?
            next [] if account.archived_at.present?

            [ unknown_component(account, account.liquid_cash? ? "Cash" : account.account_type.titleize) ]
          elsif account.currency != "USD"
            [ unknown_component(account, group_for(account), record: row, reason: "unconverted #{account.currency}") ]
          else
            [ known_account_component(account, row) ]
          end
        end
      end

      def position_components
        pairs = PositionObservation.kept.where(observed_on: ..on).distinct.pluck(:account_id, :security_id)
        pairs.filter_map do |account_id, security_id|
          account = Account.find(account_id)
          security = Security.find(security_id)
          row = PositionObservation.current_on({ account_id:, security_id: }, on)
          next if row.nil?

          if row.closed?
            known_position_component(account, security, row, amount: 0, price: nil)
          else
            price = MarketPrice.usable_on(security, on)
            if price.nil? || price.currency != "USD" || security.currency != "USD" || account.currency != "USD"
              unknown_component(account, "Investments", record: row, label: security.ticker, reason: "missing USD price")
            else
              known_position_component(account, security, row, amount: row.quantity * price.amount, price:)
            end
          end
        end
      end

      def known_account_component(account, row)
        Component.new(
          key: "account-#{account.id}",
          label: account.name,
          side: account.debt? ? :debt : :asset,
          amount: row.amount,
          state: row.observed_on == on ? :verified : :carried_forward,
          liquid: account.liquid_cash?,
          group: group_for(account),
          source_date: row.observed_on,
          record_type: "AccountObservation",
          record_id: row.id,
          unknown: false
        )
      end

      def known_position_component(account, security, row, amount:, price:)
        Component.new(
          key: "position-#{account.id}-#{security.id}",
          label: "#{security.ticker} in #{account.name}",
          side: :asset,
          amount: amount,
          state: row.observed_on == on ? :verified : :carried_forward,
          liquid: false,
          group: "Investments",
          source_date: row.observed_on,
          price_date: price&.market_on,
          price_source: price&.source,
          record_type: "PositionObservation",
          record_id: row.id,
          unknown: false,
          unrealized_gain: row.cost_basis.nil? ? nil : amount.to_d - row.cost_basis.to_d
        )
      end

      def unknown_component(account, group, record: nil, label: nil, reason: nil)
        Component.new(
          key: "unknown-#{account.id}-#{label || group}",
          label: [ label || account.name, reason ].compact.join(" — "),
          side: account.debt? ? :debt : :asset,
          amount: nil,
          state: :unknown,
          liquid: false,
          group: group,
          source_date: record&.observed_on,
          record_type: record&.class&.name,
          record_id: record&.id,
          unknown: true
        )
      end

      def group_for(account)
        if account.liquid_cash?
          "Cash"
        elsif account.property?
          "Property"
        elsif account.debt?
          "Debt"
        else
          "Investments"
        end
      end
  end
end
