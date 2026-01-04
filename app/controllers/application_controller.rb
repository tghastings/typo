# frozen_string_literal: true

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ::LoginSystem

  protect_from_forgery with: :exception

  before_action :reset_local_cache, :fire_triggers, :set_paths
  after_action :reset_local_cache

  class << self
    unless respond_to? :template_root
      def template_root
        ActionController::Base.view_paths.last
      end
    end
  end

  protected

  def set_paths
    return unless this_blog

    prepend_view_path "#{::Rails.root}/themes/#{this_blog.theme}/views"
  end

  def setup_themer
    return unless this_blog

    # Rails 8 compatible: use prepend_view_path instead of manipulating view_paths directly
    prepend_view_path "#{::Rails.root}/themes/#{this_blog.theme}/views"
  end

  def error(message = 'Record not found...', options = {})
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

  def add_to_cookies(name, value, path = nil, _expires = nil)
    cookies[name] = { value: value, path: path || "/#{controller_name}", expires: 6.weeks.from_now }
  end

  # Safe redirect that validates internal URLs belong to this blog
  # For URLs starting with the blog's base_url, allow_other_host is set to true
  # to handle cases where base_url differs from current request host
  def safe_redirect_to(url, options = {})
    blog = this_blog
    base_url = blog&.base_url || ''

    # If URL starts with our base_url, it's internal - allow cross-host since
    # base_url might be configured differently than current request host
    if url.to_s.start_with?(base_url) || url.to_s.start_with?('/')
      redirect_to url, options.merge(allow_other_host: true)
    elsif options.delete(:allow_external)
      # External URL - only allow if explicitly marked as external redirect
      redirect_to url, options.merge(allow_other_host: true)
    else
      # Reject potentially malicious external redirects
      Rails.logger.warn "Blocked external redirect attempt to: #{url}"
      redirect_to root_path, options
    end
  end

  def this_blog
    @this_blog ||= Blog.default
  end
end
