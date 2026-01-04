# frozen_string_literal: true

module Migrator
  mattr_accessor :offer_migration_when_available
  @@offer_migration_when_available = true

  def self.migrations_path
    "#{::Rails.root}/db/migrate"
  end

  def self.available_migrations
    Dir["#{migrations_path}/[0-9]*_*.rb"].sort_by { |name| name.scan(/\d+/).first.to_i }
  end

  def self.current_schema_version
    # Rails 8 compatible: use ActiveRecord::MigrationContext API

    ActiveRecord::MigrationContext.new(migrations_path).current_version
  rescue StandardError
    0
  end

  def self.max_schema_version
    # Return the highest migration version number (timestamp)
    available_migrations.last&.scan(/(\d+)_/)&.flatten&.first.to_i
  end

  def self.pending_migrations
    context = ActiveRecord::MigrationContext.new(migrations_path)
    context.migrations.select { |m| m.version > current_schema_version }
  end

  def self.pending_migration_names
    pending_migrations.map { |m| m.name.humanize }
  end

  def self.needs_migration?
    pending_migrations.any?
  end

  def self.db_supports_migrations?
    # All supported databases now support migrations in Rails 7+
    true
  end

  def self.migrate(version = nil)
    ActiveRecord::MigrationContext.new(migrations_path).migrate(version)
  end
end
