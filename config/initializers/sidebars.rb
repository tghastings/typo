# Load sidebar plugins from vendor/plugins after Rails loads
Rails.application.config.after_initialize do
  Dir[Rails.root.join('vendor/plugins/*_sidebar/lib/*.rb')].each do |sidebar_file|
    require sidebar_file
  end

  # Load textfilter plugins
  Dir[Rails.root.join('vendor/plugins/typo_textfilter_*/lib/*.rb')].each do |filter_file|
    require filter_file
  end
end
