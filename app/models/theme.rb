# frozen_string_literal: true

class Theme
  cattr_accessor :cache_theme_lookup
  @@cache_theme_lookup = false

  attr_accessor :name, :path, :description_html

  def initialize(name, path)
    @name = name
    @path = path
  end

  # TODO: Remove check for old-fashioned theme layout.
  def layout(action = :default)
    if action.to_s == 'view_page'
      return 'layouts/pages' if File.exist? "#{::Rails.root}/themes/#{name}/views/layouts/pages.html.erb"
      return "#{::Rails.root}/themes/#{name}/layouts/pages" if File.exist? "#{::Rails.root}/themes/#{name}/layouts/pages.html.erb"
    end
    return 'layouts/default' if File.exist? "#{::Rails.root}/themes/#{name}/views/layouts/default.html.erb"

    "#{::Rails.root}/themes/#{name}/layouts/default"
  end

  def description
    File.read("#{path}/about.markdown")
  rescue StandardError
    "### #{name}"
  end

  # Find a theme, given the theme name
  def self.find(name)
    new(name, theme_path(name))
  end

  def self.themes_root
    "#{::Rails.root}/themes"
  end

  def self.theme_path(name)
    "#{themes_root}/#{name}"
  end

  def self.theme_from_path(path)
    name = path.scan(/[-\w]+$/i).flatten.first
    new(name, path)
  end

  def self.find_all
    installed_themes.map do |path|
      theme_from_path(path)
    end
  end

  def self.installed_themes
    cache_theme_lookup ? @theme_cache ||= search_theme_directory : search_theme_directory
  end

  def self.search_theme_directory
    glob = "#{themes_root}/[a-zA-Z0-9]*"
    Dir.glob(glob).select do |file|
      File.readable?("#{file}/about.markdown")
    end.compact
  end
end
