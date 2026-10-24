class User < ApplicationRecord
  APPEARANCES = %w[system light dark].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  attribute :appearance, :string, default: "system"

  normalizes :email_address, with: ->(value) { value.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true
  validates :appearance, inclusion: { in: APPEARANCES }
end
