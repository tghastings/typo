class ContentController < ApplicationController
  class ExpiryFilter
    def before(controller)
      @request_time = Time.now
    end

    def after(controller)
      future_article = Article.where('published = ? AND published_at > ?', true, @request_time)
                              .order("published_at ASC")
                              .first
      if future_article
        delta = future_article.published_at - Time.now
        controller.response.lifetime = (delta <= 0) ? 0 : delta
      end
    end
  end

  include LoginSystem
  before_action :setup_themer
  helper :theme

  protected

  def auto_discovery_feed(options = {})
    # Use explicit base_url to avoid url_for issues
    base = this_blog.base_url
    @auto_discovery_url_rss = "#{base}/articles.rss"
    @auto_discovery_url_atom = "#{base}/articles.atom"
  end

  def theme_layout
    this_blog.current_theme.layout(self.action_name)
  end
end
