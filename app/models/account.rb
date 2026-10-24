class Account < ApplicationRecord
  TYPES = %w[checking savings brokerage debt property].freeze

  enum :account_type, TYPES.index_with(&:itself), validate: true

  has_many :account_observations, dependent: :destroy
  has_many :position_observations, dependent: :destroy

  validates :name, :currency, presence: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }

  scope :available_for_entry, -> { where(archived_at: nil) }

  def archive!
    update!(archived_at: Time.current)
  end

  def liquid_cash?
    checking? || savings? || brokerage?
  end
end
