module HoldingsImport
  class BulkPlanner < Planner
    def missing(planned = plan)
      uploaded = planned.filter_map { |row| [ row.account.id, row.security.id ] if row.account && row.security }.to_set
      OpenHoldings.on(Date.current).reject { |holding| uploaded.include?([ holding.account.id, holding.security.id ]) }
    end

    # Missing holdings are part of the fingerprint so a holding opened after review is caught as stale.
    def fingerprint(planned = plan)
      [ super, missing(planned).map { |holding| [ holding.account.id, holding.security.id ] } ].to_json
    end
  end
end
