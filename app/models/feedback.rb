# frozen_string_literal: true

require_dependency 'spam_protection'
class Feedback < Content
  self.table_name = 'feedback'

  include TypoGuid

  validate :feedback_not_closed, on: :create

  before_create :create_guid, :article_allows_this_feedback
  before_save :correct_url
  after_save :post_trigger
  after_save :report_classification

  has_state(:state,
            valid_states: [:unclassified, # initial state
                           :presumed_spam, :just_marked_as_spam, :spam,
                           :just_presumed_ham, :presumed_ham, :just_marked_as_ham, :ham],
            handles: %i[published? status_confirmed? just_published?
                        mark_as_ham mark_as_spam confirm_classification
                        withdraw
                        before_save_handler after_initialize_handler
                        send_notifications post_trigger report_classification])

  before_save :before_save_handler
  after_initialize :after_initialize_handler

  include States

  def self.default_order
    'created_at ASC'
  end

  def to_param
    guid
  end

  def parent
    article
  end

  def permalink_url(_anchor = :ignored, only_path = false)
    article.permalink_url("#{self.class.to_s.downcase}-#{id}", only_path)
  end

  def edit_url(_anchor = :ignored)
    blog.url_for("admin/#{self.class.to_s.downcase}s/edit/#{id}")
  end

  def delete_url(_anchor = :ignored)
    blog.url_for("admin/#{self.class.to_s.downcase}s/destroy/#{id}")
  end

  def html_postprocess(_field, html)
    helper = ContentTextHelpers.new
    helper.sanitize(helper.auto_link(html)).nofollowify
  end

  def correct_url
    return if url.blank?

    self.url = "http://#{url}" unless url =~ %r{^https?://}
  end

  def article_allows_this_feedback
    article && blog_allows_feedback? && article_allows_feedback?
  end

  def blog_allows_feedback?
    true
  end

  def akismet_options
    { user_ip: ip,
      comment_type: self.class.to_s.downcase,
      comment_author: originator,
      comment_author_email: email,
      comment_author_url: url,
      comment_content: body }
  end

  def spam_fields
    %i[title body ip url]
  end

  def classify
    begin
      return :ham if user_id
      return :spam if blog.default_moderate_comments
      return :ham unless blog.sp_global
    rescue NoMethodError
      nil # blog may not be configured yet
    end

    # Yeah, three state logic is evil...
    case sp_is_spam? || akismet_is_spam?
    when nil then :spam
    when true then :spam
    when false then :ham
    end
  end

  def akismet
    Akismet.new(blog.sp_akismet_key, blog.base_url)
  end

  def sp_is_spam?(_options = {})
    sp = SpamProtection.new(blog)
    Timeout.timeout(defined?($TESTING) ? 10 : 30) do
      spam_fields.any? do |field|
        sp.is_spam?(send(field))
      end
    end
  rescue Timeout::Error
    nil
  end

  def akismet_is_spam?(_options = {})
    return false if blog.sp_akismet_key.blank?

    begin
      Timeout.timeout(defined?($TESTING) ? 30 : 60) do
        akismet.commentCheck(akismet_options)
      end
    rescue Timeout::Error
      nil
    end
  end

  def mark_as_ham!
    mark_as_ham
    save!
  end

  def mark_as_spam!
    mark_as_spam
    save
  end

  def report_as_spam
    report_as('spam')
  end

  def report_as_ham
    report_as('ham')
  end

  def report_as(spam_or_ham)
    return if blog.sp_akismet_key.blank?

    begin
      Timeout.timeout(defined?($TESTING) ? 5 : 3600) do
        akismet.send("submit#{spam_or_ham.capitalize}", akismet_options)
      end
    rescue Timeout::Error
      nil
    end
  end

  def withdraw!
    withdraw
    save!
  end

  def confirm_classification!
    confirm_classification
    save
  end

  def feedback_not_closed
    return unless article.comments_closed?

    errors.add(:article_id, 'Comment are closed')
  end
end
