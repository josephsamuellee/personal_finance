class FinancialDecision < ApplicationRecord
  include Revisable

  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  validates :decided_on, :description, :rationale, :alternatives, :expected_effect, presence: true
end
