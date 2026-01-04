# frozen_string_literal: true

require_dependency 'spam_protection'
require 'timeout'

class Comment < Feedback
  self.table_name = 'feedback'

  belongs_to :article, optional: true
  belongs_to :user, optional: true
  content_fields :body
  validates_presence_of :author, :body

  attr_accessor :user_agent, :referrer, :permalink

  def notify_user_via_email(user)
    return unless user.notify_via_email?

    EmailNotify.send_comment(self, user)
  end

  def interested_users
    users = User.find_all_by_notify_on_comments(true)
    # XXX: What's this doing here?
    self.notify_users = users
    users
  end

  def default_text_filter
    blog.comment_text_filter.to_text_filter
  end

  def feed_title
    "Comment on #{article.title} by #{author}"
  end

  protected

  def article_allows_feedback?
    return true if article.allow_comments?

    errors.add(:article, 'Article is not open to comments')
    false
  end

  def originator
    author
  end

  def content_fields
    [:body]
  end
end
