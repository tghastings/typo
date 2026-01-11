# frozen_string_literal: true

require 'open-uri'
require 'time'
require 'rexml/document'

module Admin
  class ThemesController < Admin::BaseController
    cache_sweeper :blog_sweeper

    def index
      @themes = Theme.find_all
      @themes.each do |theme|
        theme.description_html = TextFilter.filter_text(this_blog, theme.description, nil, %i[markdown smartypants])
      end
      @active = this_blog.current_theme
    end

    def preview
      theme_name = sanitize_theme_name(params[:theme])

      # Validate theme exists in our known themes list first
      unless valid_theme?(theme_name)
        head :not_found
        return
      end

      # Build path safely using File.join and expand to canonical form
      themes_root = File.expand_path(Theme.themes_root)
      preview_path = File.expand_path(File.join(themes_root, theme_name, 'preview.png'))

      # Double-check path is within themes directory (defense in depth)
      unless preview_path.start_with?(themes_root) && File.exist?(preview_path)
        head :not_found
        return
      end

      send_file preview_path, type: 'image/png', disposition: 'inline', stream: false
    end

    def switchto
      theme_name = sanitize_theme_name(params[:theme])
      unless valid_theme?(theme_name)
        flash[:error] = _('Invalid theme')
        redirect_to '/admin/themes'
        return
      end

      this_blog.theme = theme_name
      this_blog.save
      zap_theme_caches
      this_blog.current_theme(:reload)
      flash[:notice] = _('Theme changed successfully')
      require "#{this_blog.current_theme.path}/helpers/theme_helper.rb" if File.exist? "#{this_blog.current_theme.path}/helpers/theme_helper.rb"
      redirect_to '/admin/themes'
    end

    protected

    def zap_theme_caches
      FileUtils.rm_rf(%w[stylesheets javascript images].collect { |v| page_cache_directory + "/#{v}/theme" })
    end

    private

    # Sanitize theme name to prevent path traversal
    def sanitize_theme_name(name)
      return '' if name.nil?

      # Only allow alphanumeric, underscore, hyphen, and dots (no slashes or ..)
      name.to_s.gsub(/[^a-zA-Z0-9_\-.]/, '').gsub(/\.\.+/, '.')
    end

    # Validate that the path is within the themes directory
    def valid_theme_path?(path)
      expanded = File.expand_path(path)
      themes_root = File.expand_path(Theme.themes_root)
      expanded.start_with?(themes_root)
    end

    # Check if theme is a valid installed theme
    def valid_theme?(name)
      return false if name.blank?

      Theme.find_all.any? { |t| t.name == name }
    end
  end
end
