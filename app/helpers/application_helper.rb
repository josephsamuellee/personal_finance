module ApplicationHelper
  def nav_link_options(destination, align: "center")
    current = primary_destination_current?(destination)
    {
      class: class_names("ui-nav min-h-11 min-w-11", "justify-start": align == "start", "ui-nav-current": current),
      aria: { current: (current ? "page" : nil) }
    }
  end

  def primary_destination_current?(destination)
    path = request.path
    case destination
    when :home then path == "/"
    when :expenses then path.start_with?("/expenses", "/expense_imports", "/quick-expense")
    when :assets then path.start_with?("/assets", "/accounts", "/holdings")
    when :review then path.start_with?("/reviews", "/decisions", "/compare", "/benchmark", "/recurring_items", "/savings_goals")
    else false
    end
  end

  def appearance_mode
    mode = current_user&.appearance.presence || cookies[:appearance].presence || "system"
    User::APPEARANCES.include?(mode) ? mode : "system"
  end

  def money(amount)
    return "Unknown" if amount.nil?

    tag.span(number_to_currency(amount), class: "ui-money")
  end

  def observation_label(state, date = nil)
    case state.to_sym
    when :verified then "Verified"
    when :carried_forward then "Carried forward from #{date}"
    else "Unknown"
    end
  end
end
