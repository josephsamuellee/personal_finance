module HoldingsImport
  class OpenHoldings
    Holding = Struct.new(:account, :security, :observation, keyword_init: true)

    def self.on(date)
      accounts = Account.available_for_entry.brokerage.index_by(&:id)
      pairs = PositionObservation.kept.where(account_id: accounts.keys, observed_on: ..date)
                                 .distinct.pluck(:account_id, :security_id)
      securities = Security.where(id: pairs.map(&:last)).index_by(&:id)

      holdings = pairs.filter_map do |account_id, security_id|
        observation = PositionObservation.current_on({ account_id:, security_id: }, date)
        next if observation.closed?

        Holding.new(account: accounts[account_id], security: securities[security_id], observation:)
      end
      holdings.sort_by { |holding| [ holding.account.name, holding.account.id, holding.security.ticker ] }
    end
  end
end
