# Deprecated: This plugin was for Prototype.js which is no longer used.
# These helper methods are kept as stubs for backwards compatibility.
# They will raise deprecation warnings if used.

module PrototypeHelper
  def button_to_remote(name, options = {}, html_options = {})
    Rails.logger.warn "DEPRECATION WARNING: button_to_remote is deprecated. Use modern JavaScript instead."
    button_tag(name, html_options)
  end

  def submit_to_remote(name, value, options = {})
    Rails.logger.warn "DEPRECATION WARNING: submit_to_remote is deprecated. Use modern JavaScript instead."
    submit_tag(value, name: name)
  end

  def link_to_remote(name, options = {}, html_options = nil)
    Rails.logger.warn "DEPRECATION WARNING: link_to_remote is deprecated. Use modern JavaScript instead."
    link_to(name, '#', html_options || {})
  end

  def form_remote_tag(options = {}, &block)
    Rails.logger.warn "DEPRECATION WARNING: form_remote_tag is deprecated. Use form_tag with modern JavaScript instead."
    options[:html] ||= {}
    form_tag(options[:html].delete(:action) || url_for(options[:url]), options[:html], &block)
  end

  def remote_form_for(record_or_name_or_array, *args, &proc)
    Rails.logger.warn "DEPRECATION WARNING: remote_form_for is deprecated. Use form_with instead."
    form_for(record_or_name_or_array, *args, &proc)
  end
  alias_method :form_remote_for, :remote_form_for

  def observe_field(field_id, options = {})
    Rails.logger.warn "DEPRECATION WARNING: observe_field is deprecated. Use modern JavaScript instead."
    # Return empty string - no longer outputs Prototype.js code
    "".html_safe
  end

  def observe_form(form_id, options = {})
    Rails.logger.warn "DEPRECATION WARNING: observe_form is deprecated. Use modern JavaScript instead."
    "".html_safe
  end

  def periodically_call_remote(options = {})
    Rails.logger.warn "DEPRECATION WARNING: periodically_call_remote is deprecated. Use modern JavaScript instead."
    "".html_safe
  end

  def remote_function(options = {})
    Rails.logger.warn "DEPRECATION WARNING: remote_function is deprecated. Use modern JavaScript instead."
    ""
  end
end

ActionController::Base.helper PrototypeHelper
