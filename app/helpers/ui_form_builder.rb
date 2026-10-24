class UiFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(method, options = {})
    super(method, field_options(method, options))
  end

  def email_field(method, options = {})
    super(method, field_options(method, options))
  end

  def password_field(method, options = {})
    super(method, field_options(method, options))
  end

  def number_field(method, options = {})
    super(method, field_options(method, options))
  end

  def currency_field(method, options = {})
    options = (options || {}).dup
    options[:inputmode] = "decimal"
    options[:autocomplete] = "off"
    value = options.key?(:value) ? options[:value] : @object.public_send(method)
    options[:placeholder] = "$1,000" if value.blank?
    text_field(method, options)
  end

  def date_field(method, options = {})
    super(method, field_options(method, options))
  end

  def text_area(method, options = {})
    super(method, field_options(method, options))
  end

  def file_field(method, options = {})
    super(method, field_options(method, options))
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    super(method, choices, options, field_options(method, html_options), &block)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    super(method, collection, value_method, text_method, options, field_options(method, html_options))
  end

  def error_message(method)
    return unless @object.respond_to?(:errors) && @object.errors[method].present?

    @template.tag.p(@object.errors[method].to_sentence, id: field_error_id(method), class: "text-sm text-red-700 dark:text-red-300")
  end

  def label(method, text = nil, options = {}, &block)
    if text.is_a?(Hash)
      options = text
      text = nil
    end
    options = options.dup
    options[:class] = @template.class_names("mb-1 block text-sm font-medium", options[:class])
    super(method, text, options, &block)
  end

  def submit(value = nil, options = {})
    value, options = nil, value if value.is_a?(Hash)
    options = (options || {}).dup
    options[:class] = @template.class_names("ui-button", options[:class])
    options[:data] = (options[:data] || {}).reverse_merge(turbo_submits_with: "Saving…")
    super(value, options)
  end

  private
    def field_options(method, options)
      options = (options || {}).dup
      options[:class] = @template.class_names("ui-field", options[:class])
      if @object.respond_to?(:errors) && @object.errors[method].present?
        options[:"aria-invalid"] = true
        options[:"aria-describedby"] = field_error_id(method)
      end
      options
    end

    def field_error_id(method)
      "#{@object_name}_#{method}_error"
    end
end
