# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ::LoginSystem
  protect_from_forgery with: :exception

  before_action :reset_local_cache, :fire_triggers, :set_paths
  after_action :reset_local_cache

  class << self
    unless self.respond_to? :template_root
      def template_root
        ActionController::Base.view_paths.last
      end
    end
  end

  protected

  def set_paths
    prepend_view_path "#{::Rails.root.to_s}/themes/#{this_blog.theme}/views"
  end

  def setup_themer
    self.class.view_paths = ::ActionController::Base.view_paths.dup.unshift("#{::Rails.root.to_s}/themes/#{this_blog.theme}/views")
  end

  def error(message = "Record not found...", options = {})
    @message = message.to_s
    render 'articles/error', status: options[:status] || 404, formats: [:html]
  end

  def fire_triggers
    Trigger.fire if defined?(Trigger)
  end

  def reset_local_cache
    @current_user = nil
  end

  # The base URL for this request
  def blog_base_url
    url_for(controller: '/articles').gsub(%r{/$}, '')
  end

  def add_to_cookies(name, value, path = nil, expires = nil)
    cookies[name] = { value: value, path: path || "/#{controller_name}", expires: 6.weeks.from_now }
  end

  def this_blog
    @blog ||= Blog.default
  end
end
