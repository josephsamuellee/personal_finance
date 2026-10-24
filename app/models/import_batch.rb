class ImportBatch < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :nullify

  validates :status, presence: true
end
