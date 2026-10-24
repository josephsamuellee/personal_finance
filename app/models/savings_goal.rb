class SavingsGoal < ApplicationRecord
  validates :amount, :starts_on, :reason, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validate :period_does_not_overlap
  validate :end_is_on_or_after_start

  def self.applicable_on(date)
    where(starts_on: ..date).where("ends_on IS NULL OR ends_on >= ?", date).order(starts_on: :desc).first
  end

  def period_end
    ends_on || Date.new(9999, 12, 31)
  end

  private
    def end_is_on_or_after_start
      return if ends_on.blank? || starts_on.blank?
      return if ends_on >= starts_on

      errors.add(:ends_on, "must be on or after the start date")
    end

    def period_does_not_overlap
      return if starts_on.blank?

      overlap = self.class.where.not(id: id).any? do |other|
        starts_on <= other.period_end && other.starts_on <= period_end
      end
      errors.add(:starts_on, "overlaps another savings target") if overlap
    end
end
