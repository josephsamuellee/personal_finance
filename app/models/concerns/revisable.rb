module Revisable
  extend ActiveSupport::Concern

  IGNORED_REVISION_COLUMNS = %w[updated_at created_at].freeze

  included do
    has_many :record_revisions, as: :record, dependent: :delete_all
    attr_accessor :revision_user, :revision_reason
    after_update :write_revision
  end

  private
    def write_revision
      diff = saved_changes.except(*IGNORED_REVISION_COLUMNS)
      return if diff.empty?

      record_revisions.create!(
        revision_number: record_revisions.maximum(:revision_number).to_i + 1,
        previous_values: diff.transform_values { |value| json_ready(value.first) },
        new_values: diff.transform_values { |value| json_ready(value.last) },
        user: revision_user || Current.user,
        reason: revision_reason
      )
    end

    def json_ready(value)
      case value
      when BigDecimal then value.to_s
      when Date then value.iso8601
      when Time, ActiveSupport::TimeWithZone then value.iso8601
      else value
      end
    end
end
