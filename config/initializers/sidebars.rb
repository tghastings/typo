# frozen_string_literal: true

# Load sidebar plugins from vendor/plugins
# Use to_prepare so plugins are reloaded when Rails reloads classes in development
Rails.application.config.to_prepare do
  # Load sidebar plugins - remove existing class first to avoid superclass mismatch
  Dir[Rails.root.join('vendor/plugins/*_sidebar/lib/*.rb')].each do |sidebar_file|
    # Extract class name from file (e.g., amazon_sidebar.rb -> AmazonSidebar)
    class_name = File.basename(sidebar_file, '.rb').camelize
    Object.send(:remove_const, class_name) if Object.const_defined?(class_name, false)
    load sidebar_file
  end
end

# Load textfilter plugins - use to_prepare so they reload with Rails classes
# This ensures @@filter_map stays populated when classes are reloaded in development
Rails.application.config.to_prepare do
  Dir[Rails.root.join('vendor/plugins/typo_textfilter_*/lib/*.rb')].each do |filter_file|
    # Extract class name from file (e.g., typo_textfilter_amazon.rb -> Amazon)
    # These are nested under Typo::Textfilter
    base_name = File.basename(filter_file, '.rb').sub('typo_textfilter_', '')
    class_name = base_name.camelize
    Typo::Textfilter.send(:remove_const, class_name) if defined?(Typo::Textfilter) && Typo::Textfilter.const_defined?(class_name, false)
    load filter_file
  end
end

# Add sidebar plugin view paths (only needs to happen once)
Rails.application.config.after_initialize do
  Dir[Rails.root.join('vendor/plugins/*_sidebar/app/views')].each do |view_path|
    ActionController::Base.prepend_view_path(view_path)
  end
end
