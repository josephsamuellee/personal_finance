class RecurringItem < ApplicationRecord
  DIRECTIONS = %w[income obligation].freeze
  FREQUENCIES = %w[weekly monthly quarterly yearly].freeze
  TREATMENTS = %w[included_in_tracked_spending additional].freeze

  enum :direction, DIRECTIONS.index_with(&:itself), validate: true
  enum :frequency, FREQUENCIES.index_with(&:itself), validate: true
  enum :treatment, TREATMENTS.index_with(&:itself), validate: true

  validates :name, :amount, :starts_on, presence: true
  validates :amount, numericality: { greater_than: 0 }

  scope :active_on, ->(date) { where(starts_on: ..date).where("ends_on IS NULL OR ends_on >= ?", date) }

  def self.monthly_total(date, direction:, treatment: nil)
    scope = active_on(date).where(direction: direction)
    scope = scope.where(treatment: treatment) if treatment
    scope.sum { |item| item.monthly_equivalent }
  end

  def monthly_equivalent
    case frequency
    when "weekly" then amount * 52 / 12
    when "quarterly" then amount / 3
    when "yearly" then amount / 12
    else amount
    end
  end

  def next_occurrence_on(from:)
    return if starts_on.blank?
    return if ends_on && ends_on < from

    date = starts_on
    2400.times do
      return if ends_on && date > ends_on
      return date if date >= from

      date = advance(date)
    end
  end

  private
    def advance(date)
      case frequency
      when "weekly" then date + 7
      when "quarterly" then date >> 3
      when "yearly" then date >> 12
      else date >> 1
      end
    end
end
