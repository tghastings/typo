# frozen_string_literal: true

require 'uri'

class Content < ActiveRecord::Base
  belongs_to :text_filter, optional: true

  has_many :notifications, foreign_key: 'content_id'
  has_many :notify_users, -> { distinct }, through: :notifications, source: 'notify_user'
  has_many :redirections
  has_many :redirects, through: :redirections, dependent: :destroy

  def notify_users=(collection)
    return notify_users.clear if collection.empty?

    self.class.transaction do
      notifications.clear
      collection.uniq.each do |u|
        if persisted?
          notifications.create(notify_user: u)
        else
          notifications.build(notify_user: u)
        end
      end
    end
  end

  has_many :triggers, as: :pending_item, dependent: :delete_all

  scope :published_at_like, lambda { |date_at|
    where(published_at: (
      case date_at
      when /\d{4}-\d{2}-\d{2}/
        DateTime.strptime(date_at, '%Y-%m-%d').beginning_of_day..DateTime.strptime(date_at, '%Y-%m-%d').end_of_day
      when /\d{4}-\d{2}/
        DateTime.strptime(date_at, '%Y-%m').beginning_of_month..DateTime.strptime(date_at, '%Y-%m').end_of_month
      when /\d{4}/
        DateTime.strptime(date_at, '%Y').beginning_of_year..DateTime.strptime(date_at, '%Y').end_of_year
      else
        date_at
      end
    ))
  }

  scope :user_id, ->(user_id) { where(user_id: user_id) }
  scope :published, -> { where(published: true) }
  scope :not_published, -> { where(published: false) }
  scope :draft, -> { where(state: 'draft') }
  scope :no_draft, -> { where.not(state: 'draft').order('published_at DESC') }
  scope :searchstring, lambda { |search_string|
    tokens = search_string.split.collect { |c| "%#{c.downcase}%" }
    conditions = (['(LOWER(body) LIKE ? OR LOWER(extended) LIKE ? OR LOWER(title) LIKE ?)'] * tokens.size).join(' AND ')
    where(["state = ? AND #{conditions}", 'published', *tokens.collect { |token| [token] * 3 }.flatten])
  }
  scope :already_published, -> { where('published = ? AND published_at < ?', true, Time.now).order(default_order) }

  serialize :whiteboard, coder: YAML

  attr_accessor :just_changed_published_status
  alias just_changed_published_status? just_changed_published_status

  after_save :invalidates_cache?
  after_destroy ->(c) { c.invalidates_cache?(true) }

  include Stateful

  def invalidates_cache?(on_destruction = false)
    @invalidates_cache ||= if on_destruction
                             just_changed_published_status? || published?
                           else
                             # Use saved_changes for after_save callbacks, or previous_changes for already saved records
                             has_changes = saved_changes.present? || previous_changes.present? || changed?
                             (has_changes && published?) || just_changed_published_status?
                           end
  end

  def shorten_url
    return unless published

    r = Redirect.new
    r.from_path = r.shorten
    r.to_path = permalink_url

    unless (red = redirects.first).nil?
      return if red.to_path == permalink_url

      r.from_path = red.from_path
      red.destroy
      redirects.clear
    end

    redirects << r
  end

  class << self
    def content_fields(*attribs)
      class_eval "def content_fields; #{attribs.inspect}; end", __FILE__, __LINE__
    end

    def find_published(_what = :all, _options = {})
      published.order(default_order)
    end

    def default_order
      'published_at DESC'
    end

    def find_already_published(_what = :all, at = nil, _options = {})
      at ||= Time.now
      already_published.where('published_at < ?', at)
    end

    ALLOWED_DATE_COLUMNS = %w[published_at created_at updated_at].freeze

    def find_by_published_at(column_name = :published_at)
      # Whitelist column names to prevent SQL injection
      safe_column = column_name.to_s
      raise ArgumentError, "Invalid column name: #{column_name}" unless ALLOWED_DATE_COLUMNS.include?(safe_column)

      # Use sanitize_sql_for_conditions for the type value
      sanitized_type = sanitize_sql_for_conditions(['type = ?', name])
      from_where = "FROM #{table_name} WHERE #{safe_column} is not NULL AND #{sanitized_type}"
      find_by_sql("SELECT strftime('%Y-%m', #{safe_column}) AS publication #{from_where} GROUP BY publication ORDER BY publication DESC")
    end

    def function_search_no_draft(search_hash)
      list_function = []
      search_hash ||= {}

      list_function << 'searchstring(search_hash[:searchstring])' if search_hash[:searchstring] && !search_hash[:searchstring].to_s.empty?

      if search_hash[:published_at] && /(\d\d\d\d)-(\d\d)/ =~ search_hash[:published_at]
        list_function << 'published_at_like(search_hash[:published_at])'
      end

      list_function << 'user_id(search_hash[:user_id])' if search_hash[:user_id]&.to_i&.positive?

      if search_hash[:published]
        list_function << 'published' if search_hash[:published].to_s == '1'
        list_function << 'not_published' if search_hash[:published].to_s == '0'
      end

      list_function
    end
  end

  def html_map(field)
    content_fields.include? field
  end

  def html(field = :all)
    if field == :all
      generate_html(:all, content_fields.map { |f| self[f].to_s }.join("\n\n"))
    elsif html_map(field)
      generate_html(field)
    else
      raise "Unknown field: #{field.inspect} in content.html"
    end
  end

  def generate_html(field, text = nil)
    text ||= self[field].to_s
    html = text_filter.filter_text_for_content(blog, text, self) || text
    html_postprocess(field, html).to_s.html_safe
  end

  def html_postprocess(_field, html)
    html
  end

  def whiteboard
    self[:whiteboard] ||= {}
  end

  def default_text_filter
    blog.text_filter_object
  end

  def text_filter
    if self[:text_filter_id] && !self[:text_filter_id].zero?
      TextFilter.find(self[:text_filter_id])
    else
      default_text_filter
    end
  end

  def text_filter=(filter)
    self.text_filter_id = filter.to_text_filter.id
  end

  def blog
    @blog ||= Blog.default
  end

  def publish!
    self.published = true
    save!
  end

  def withdraw!
    withdraw
    save!
  end

  def published_at
    self[:published_at] || self[:created_at]
  end

  def send_notification_to_user(user)
    notify_user_via_email(user)
  end

  def really_send_notifications
    interested_users.each do |value|
      send_notification_to_user(value)
    end
    true
  end

  def get_rss_description
    return '' unless blog.rss_description
    return '' unless respond_to?(:user) && user&.name

    rss_desc = blog.rss_description_text
    rss_desc.gsub!('%author%', user.name)
    rss_desc.gsub!('%blog_url%', blog.base_url)
    rss_desc.gsub!('%blog_name%', blog.blog_name)
    rss_desc.gsub!('%permalink_url%', permalink_url)
    rss_desc
  end

  def normalized_permalink_url
    @normalized_permalink_url ||= Addressable::URI.parse(permalink_url).normalize
  end

  def short_url
    return unless published && redirects.any?

    blog.url_for(redirects.last.from_path, only_path: false)
  end
end

class Object
  def to_text_filter
    TextFilter.find_by(name: to_s) || TextFilter.find_by(name: 'none') || TextFilter.find_or_create_by!(name: 'none') do |tf|
      tf.description = 'None'
      tf.markup = 'none'
      tf.filters = ''
      tf.params = ''
    end
  end
end

class ContentTextHelpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TextHelper
end
