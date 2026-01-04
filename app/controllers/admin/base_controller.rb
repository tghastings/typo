# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    cattr_accessor :look_for_migrations
    @@look_for_migrations = true
    layout 'administration'
    before_action :login_required, except: %i[login signup]
    before_action :look_for_needed_db_updates, except: %i[login signup update_database migrate]

    private

    def look_for_needed_db_updates
      return unless Migrator.offer_migration_when_available

      return unless Migrator.current_schema_version != Migrator.max_schema_version

      redirect_to controller: '/admin/settings',
                  action: 'update_database'
    end
  end
end
