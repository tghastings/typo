# frozen_string_literal: true

module Admin
  class SettingsController < Admin::BaseController
    cache_sweeper :blog_sweeper

    def index
      this_blog.base_url = blog_base_url if this_blog.base_url.blank?
      load_settings
    end

    def write
      load_settings
    end

    def feedback
      load_settings
    end

    def errors
      load_settings
    end

    def redirect
      flash[:notice] = _('Please review and save the settings before continuing')
      redirect_to action: 'index'
    end

    ALLOWED_ACTIONS = %w[index write feedback errors].freeze

    def update
      if request.post?
        Blog.transaction do
          params[:setting].each { |k, v| this_blog.send("#{k}=", v) }
          this_blog.save
          flash[:notice] = _('config updated.')
        end

        redirect_action = ALLOWED_ACTIONS.include?(params[:from]) ? params[:from] : 'index'
        redirect_to action: redirect_action
      end
    rescue ActiveRecord::RecordInvalid
      render_action = ALLOWED_ACTIONS.include?(params[:from]) ? params[:from] : 'index'
      render action: render_action
    end

    def update_database
      @current_version = Migrator.current_schema_version
      @needed_version = Migrator.max_schema_version
      @support = Migrator.db_supports_migrations?
      @needed_migrations = Migrator.pending_migration_names
    end

    def migrate
      return unless request.post?

      Migrator.migrate
      redirect_to action: 'update_database'
    end

    private

    def load_settings
      @setting = this_blog
    end
  end
end
