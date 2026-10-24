class FinancialReview < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  validates :review_on, :commentary, presence: true

  before_validation :freeze_snapshot, on: :create

  private
    def freeze_snapshot
      return if review_on.blank?

      snapshot = Reporting::Snapshot.new(on: review_on)
      self.calculation_version = Reporting::CALCULATION_VERSION
      self.inputs = snapshot.to_h
      self.record_references = snapshot.references
    end
end
