# Settings specified here will take precedence over those in config/environment.rb

TypoBlog::Application.configure do
  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Eager load code on boot for Rails 7
  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  config.active_support.deprecation = :stderr

  # Assets configuration for test environment
  config.assets.compile = true
  config.assets.check_precompiled_asset = false
  config.assets.debug = false

  # Raise exceptions for disallowed deprecations
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Configure Migrator if defined
  config.after_initialize do
    if defined?(Migrator)
      Migrator.offer_migration_when_available = false
    end
  end
end
