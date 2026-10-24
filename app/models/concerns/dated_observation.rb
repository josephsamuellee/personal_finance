module DatedObservation
  extend ActiveSupport::Concern

  included do
    include Revisable
    belongs_to :created_by, class_name: "User", optional: true
    belongs_to :updated_by, class_name: "User", optional: true
    scope :kept, -> { where(discarded_at: nil) }
    validates :observed_on, :sequence, presence: true
    validates :sequence, numericality: { only_integer: true, greater_than: 0 }
  end

  class_methods do
    def current_on(scope_attrs, date)
      kept.where(scope_attrs).where(observed_on: ..date).order(observed_on: :desc, sequence: :desc).first
    end

    def state_on(scope_attrs, date)
      row = current_on(scope_attrs, date)
      return [ :unknown, nil ] unless row

      state = row.observed_on == date ? :verified : :carried_forward
      [ state, row ]
    end

    def revise_current!(scope_attrs, observed_on:, updated_by:, **values)
      row = kept.where(scope_attrs).where(observed_on: observed_on).order(sequence: :desc).first
      if row
        row.revision_user = updated_by
        row.update!(values.merge(updated_by: updated_by))
        row
      else
        create!(scope_attrs.merge(values).merge(observed_on:, sequence: next_sequence(scope_attrs, observed_on), created_by: updated_by, updated_by: updated_by))
      end
    end

    def add_another!(scope_attrs, observed_on:, updated_by:, **values)
      create!(scope_attrs.merge(values).merge(observed_on:, sequence: next_sequence(scope_attrs, observed_on), created_by: updated_by, updated_by: updated_by))
    end

    def next_sequence(scope_attrs, observed_on)
      where(scope_attrs).where(observed_on: observed_on).maximum(:sequence).to_i + 1
    end
  end

  def discard_from_active_use!(user:)
    self.revision_user = user
    self.revision_reason = "removed from active use"
    update!(discarded_at: Time.current, updated_by: user)
  end
end
