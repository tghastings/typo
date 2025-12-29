require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

# Load legacy plugin libraries that are needed early
require_relative '../vendor/plugins/typo_login_system/lib/access_control'
require_relative '../vendor/plugins/typo_login_system/lib/login_system'
require_relative '../vendor/plugins/localization/lib/localization'
require_relative '../lib/typo_version'
require_relative '../vendor/plugins/calendar_date_select/lib/calendar_date_select/calendar_date_select'
require_relative '../vendor/plugins/calendar_date_select/lib/calendar_date_select/form_helpers'
require_relative '../vendor/plugins/calendar_date_select/lib/calendar_date_select/includes_helper'

module TypoBlog
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 7.0
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.

    # Setup the cache path
    config.cache_store = :file_store, Rails.root.join('public/cache/')

    # Autoload paths
    config.autoload_paths += %W(
      #{config.root}/app/apis
      #{config.root}/lib
    )

    # Ignore action_web_service directory from Zeitwerk autoloader
    # (legacy library with non-standard naming conventions)
    Rails.autoloaders.main.ignore("#{config.root}/lib/action_web_service")

    # Add public/javascripts to asset paths for legacy assets
    config.assets.paths << Rails.root.join('public', 'javascripts')
    config.assets.paths << Rails.root.join('public', 'stylesheets')

    # Precompile legacy assets
    config.assets.precompile += %w( ckeditor/* )

    # Filter sensitive parameters from the log file
    config.filter_parameters += [:password, :password_confirmation]

    # Encoding
    config.encoding = "utf-8"

    # Time zone
    config.time_zone = 'UTC'

    # Disable some Rails 7 defaults that require setup
    config.active_storage.service_configurations = {}
  end
end

# Load included libraries safely
begin
  require 'format'
rescue LoadError
  # format.rb may not exist yet
end

begin
  require 'transforms'
rescue LoadError
  # transforms.rb may not exist yet
end

# Date formats
Date::DATE_FORMATS.merge!(
  :long_weekday => '%a %B %e, %Y %H:%M'
)
