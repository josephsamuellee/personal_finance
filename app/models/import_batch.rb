class ImportBatch < ApplicationRecord
  KINDS = %w[expenses holdings].freeze

  belongs_to :user
  belongs_to :account, optional: true
  has_many :expenses, dependent: :nullify

  validates :status, presence: true
  validates :kind, inclusion: { in: KINDS }
end
