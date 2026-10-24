# One form object behind the holding editor's save and the combined
# add-holding workflow. It classifies what the user actually changed and
# saves only intentional changes:
#   :verify     - the explicit verification gesture
#   :create     - the combined add-holding save (security + observation + price)
#   :price_only - only the market price changed
#   :edit       - the on-date observation exists and quantity/cost changed
#   :new        - no observation exists on the selected date
#   :no_change  - every value matches what was prepopulated
class HoldingForm
  include ActiveModel::Model

  attr_accessor :account, :security, :user, :gesture,
                :observed_on, :quantity, :cost_basis, :price, :note, :reason,
                :ticker, :exchange, :currency, :historical_ack, :correction_id

  validate :observed_on_is_present_and_not_future
  validate :historical_date_is_acknowledged
  validate :holding_values_are_valid
  validate :price_value_is_valid, if: :price?
  validate :create_price_is_available, if: -> { gesture == "create" }
  validate :create_identity_is_available, if: -> { gesture == "create" }

  def observed_on
    parse_date(@observed_on)
  end

  def quantity_value
    BigDecimal(@quantity.to_s) if @quantity.present?
  rescue ArgumentError, TypeError
    nil
  end

  def cost_basis_value
    BigDecimal(@cost_basis.to_s) if @cost_basis.present?
  rescue ArgumentError, TypeError
    nil
  end

  def price_value
    BigDecimal(@price.to_s) if @price.present?
  rescue ArgumentError, TypeError
    nil
  end

  def price?
    @price.present?
  end

  # The effective price saved exactly on the selected market date.
  def effective_price
    return unless security && observed_on

    MarketPrice.effective_on(security, observed_on)
  end

  # The latest applicable observation on or before the selected date.
  def current_observation
    return @current_observation if defined?(@current_observation)

    @current_observation =
      if account && security && observed_on
        PositionObservation.current_on({ account_id: account.id, security_id: security.id }, observed_on)
      end
  end

  # The observation recorded exactly on the selected date, if any.
  def on_date_observation
    return unless account && security && observed_on

    PositionObservation.kept.where(account: account, security: security, observed_on: observed_on)
                       .order(sequence: :desc).first
  end

  def intent
    @intent ||=
      case gesture
      when "verify" then :verify
      when "create" then :create
      when "add" then :add
      when "correct" then :correct
      else
        if !holding_values_changed? && price_changed?
          :price_only
        elsif on_date_observation.nil?
          :new
        elsif holding_values_changed?
          :edit
        else
          :no_change
        end
      end
  end

  def intent_label
    {
      verify: "Verify", create: "Save holding", add: "Add observation",
      correct: "Correct observation", price_only: "Update price",
      new: "New observation", edit: "Edit observation", no_change: "No changes"
    }.fetch(intent)
  end

  def historical?
    observed_on.present? && observed_on < Date.current
  end

  # Saves only the intentional change. Returns a result hash describing
  # what happened. Raises nothing on validation failure; the caller checks
  # #valid? first.
  def save!
    raise ActiveRecord::RecordInvalid.new(self) unless valid?

    case intent
    when :price_only then save_price_only!
    when :no_change then { intent: :no_change }
    when :new then save_observation!
    when :edit then save_observation!
    when :verify then save_verification!
    when :add then add_observation!
    when :correct then correct_observation!
    when :create then create_holding!
    end
  end

  private
    def save_price_only!
      MarketPrice.upsert_effective!(
        security: security, amount: price_value, market_on: observed_on,
        currency: security.currency, source: "manual", entered_by: user
      )
      { intent: :price_only }
    end

    # Records a dated observation only when the values actually differ
    # from the latest applicable observation; an unchanged :new save
    # records nothing.
    def save_observation!
      if redundant?
        { intent: :no_change }
      else
        PositionObservation.revise_current!({ account: account, security: security },
                                            observed_on:, updated_by: user,
                                            quantity: quantity_value, cost_basis: cost_basis_value)
        { intent: intent }
      end
    end

    def save_verification!
      PositionObservation.revise_current!({ account: account, security: security },
                                          observed_on:, updated_by: user,
                                          quantity: quantity_value, cost_basis: cost_basis_value)
      { intent: :verify }
    end

    def add_observation!
      PositionObservation.add_another!({ account: account, security: security },
                                        observed_on:, updated_by: user,
                                        quantity: quantity_value, cost_basis: cost_basis_value,
                                        reason: reason)
      { intent: :add }
    end

    def correct_observation!
      observation = PositionObservation.kept.find(@correction_id)
      observation.revision_user = user
      observation.revision_reason = reason
      observation.update!(quantity: quantity_value, cost_basis: cost_basis_value,
                           observed_on:, updated_by: user)
      { intent: :correct }
    end

    def create_holding!
      security_to_use = nil

      ActiveRecord::Base.transaction do
        security_to_use =
          if security
            security.tap { |shared| shared.update!(note:) if note.present? }
          else
            Security.find_or_create_by_identity!(ticker:, exchange:, currency: currency || "USD", note:)
          end

        effective = MarketPrice.effective_on(security_to_use, observed_on)
        if price.present? && (effective.nil? || !same_number?(effective.amount, price_value))
          upsert_price_for(security_to_use)
        end

        PositionObservation.revise_current!({ account: account, security: security_to_use },
                                            observed_on:, updated_by: user,
                                            quantity: quantity_value, cost_basis: cost_basis_value)
      end

      { intent: :create, security: security_to_use }
    end

    def upsert_price_for(security_to_use)
      MarketPrice.upsert_effective!(
        security: security_to_use, amount: price_value, market_on: observed_on,
        currency: security_to_use.currency, source: "manual", entered_by: user
      )
    end

    def create_price_is_available
      return if observed_on.nil? || price.present?

      security_to_check = security
      return if security_to_check && MarketPrice.effective_on(security_to_check, observed_on)

      errors.add(:price, "A market price for this date is required before the holding can be saved")
    end

    def create_identity_is_available
      return unless security.nil? && @ticker.blank?

      errors.add(:ticker, "Choose a security or enter a new ticker")
    end

    def redundant?
      row = current_observation
      return false if row.nil?

      same_number?(row.quantity, quantity_value) && same_number?(row.cost_basis, cost_basis_value) &&
        (!price? || !price_changed?)
    end

    def holding_values_changed?
      row = current_observation
      return true if row.nil?
      return true if @quantity.blank? || @cost_basis.blank?

      !same_number?(row.quantity, quantity_value) || !same_number?(row.cost_basis, cost_basis_value)
    end

    def price_changed?
      return false unless price?

      effective = effective_price
      effective.nil? || !same_number?(effective.amount, price_value)
    end

    def same_number?(left, right)
      return false if left.blank? || right.blank?

      BigDecimal(left.to_s) == BigDecimal(right.to_s)
    rescue ArgumentError
      false
    end

    def parse_date(value)
      Date.iso8601(value.to_s) if value.present?
    rescue Date::Error, TypeError
      nil
    end

    def observed_on_is_present_and_not_future
      if observed_on.nil?
        errors.add(:observed_on, "Enter a valid observation date")
      elsif observed_on > Date.current
        errors.add(:observed_on, "cannot be in the future")
      end
    end

    def historical_date_is_acknowledged
      return unless valid_date_for_acknowledgment?

      errors.add(:historical_ack, "must be acknowledged to save a past date") if historical_ack.to_s != "1"
    end

    def valid_date_for_acknowledgment?
      observed_on.present? && observed_on < Date.current && gesture != "correct"
    end

    def holding_values_are_valid
      if @quantity.blank?
        errors.add(:quantity, "can't be blank")
      elsif quantity_value.nil?
        errors.add(:quantity, "is not a number")
      elsif quantity_value.negative?
        errors.add(:quantity, "must be greater than or equal to 0")
      end

      if @cost_basis.blank?
        errors.add(:cost_basis, "can't be blank")
      elsif cost_basis_value.nil?
        errors.add(:cost_basis, "is not a number")
      elsif cost_basis_value.negative?
        errors.add(:cost_basis, "must be greater than or equal to 0")
      end
    end

    def price_value_is_valid
      if price_value.nil?
        errors.add(:price, "is not a number")
      elsif price_value <= 0
        errors.add(:price, "must be greater than 0")
      end
    end
end
