# frozen_string_literal: true

require_dependency 'spam_protection'

class Trackback < Feedback
  self.table_name = 'feedback'

  belongs_to :article, optional: true
  content_fields :excerpt
  validates_presence_of :title, :excerpt, :url

  def initialize(*args, &)
    # Handle ActionController::Parameters for Rails 7 compatibility
    args[0] = args.first.to_unsafe_h if args.first.is_a?(ActionController::Parameters)
    super
    self.title ||= url
    self.blog_name ||= ''
  end

  before_create :process_trackback

  def process_trackback
    return unless excerpt.length >= 251

    # this limits excerpt to 250 chars, including the trailing "..."
    self.excerpt = excerpt[0..246] << '...'
  end

  def article_allows_feedback?
    return true if article.allow_pings?

    errors.add(:article, 'Article is not pingable')
    false
  end

  def blog_allows_feedback?
    return true unless blog.global_pings_disable

    errors.add(:article, 'Pings are disabled')
    false
  end

  def originator
    blog_name
  end

  def body
    excerpt
  end

  def body=(newval)
    self.excerpt = newval
  end

  def rss_author(xml); end

  def rss_title(xml)
    xml.title feed_title
  end

  def feed_title
    "Trackback from #{blog_name}: #{title} on #{article.title}"
  end
end
