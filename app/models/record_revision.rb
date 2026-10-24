class RecordRevision < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :user, optional: true

  validates :revision_number, :previous_values, :new_values, presence: true
end
