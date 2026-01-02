# coding: utf-8
require 'uri'
require 'net/http'

class Article < Content
  include TypoGuid
  include ConfigManager

  serialize :settings, coder: YAML, type: Hash

  content_fields :body, :extended

  validates :guid, uniqueness: true
  validates :title, presence: true

  belongs_to :user, optional: true

  has_many :pings, -> { order('created_at ASC') }, dependent: :destroy
  has_many :trackbacks, -> { order('created_at ASC') }, dependent: :destroy
  has_many :feedback, -> { order('created_at DESC') }
  has_many :resources, -> { order('created_at DESC') }, dependent: :nullify
  has_many :categorizations
  has_many :categories, through: :categorizations
  has_many :triggers, as: :pending_item

  has_many :comments, -> { order('created_at ASC') }, dependent: :destroy do
    def ham
      where(state: ["presumed_ham", "ham"])
    end

    def spam
      where(state: ["presumed_spam", "spam"])
    end
  end

  has_many :published_comments, -> { where(published: true).order('created_at ASC') }, class_name: "Comment"
  has_many :published_trackbacks, -> { where(published: true).order('created_at ASC') }, class_name: "Trackback"
  has_many :published_feedback, -> { where(published: true).order('created_at ASC') }, class_name: "Feedback"

  has_and_belongs_to_many :tags

  before_create :set_defaults, :create_guid
  after_create :add_notifications
  before_save :set_published_at, :ensure_settings_type, :set_permalink, :regenerate_whiteboard
  after_save :post_trigger, :keywords_to_tags, :shorten_url, :send_pings, :send_notifications

  scope :category, ->(category_id) { joins(:categorizations).where('categorizations.category_id = ?', category_id) }
  scope :drafts, -> { where(state: 'draft').order('created_at DESC') }
  scope :without_parent, -> { where(parent_id: nil) }
  scope :child_of, ->(article_id) { where(parent_id: article_id) }
  scope :published, -> { where(published: true, published_at: Time.at(0)..Time.now).order('published_at DESC') }
  scope :pending, -> { where('state = ? and published_at > ?', 'publication_pending', Time.now).order('published_at DESC') }
  scope :withdrawn, -> { where(state: 'withdrawn').order('published_at DESC') }
  scope :published_at, ->(time_params) { where(published: true, published_at: Article.time_delta(*time_params)).order('published_at DESC') }

  # Note: password is stored as a database column, not in settings
  # The setting macro is not used because the column already exists

  def initialize(*args)
    # Handle ActionController::Parameters for Rails 7 compatibility
    if args.first.is_a?(ActionController::Parameters)
      args[0] = args.first.to_unsafe_h
    end
    super
    begin
      self.settings ||= {}
    rescue Exception => e
      self.settings = {}
    end
  end

  def set_permalink
    return if self.state == 'draft'
    self.permalink = self.title.to_permalink if self.permalink.blank?
  end

  def regenerate_whiteboard
    if body_changed? || extended_changed?
      self.whiteboard = {}
      html(:body)
      html(:extended) if extended.present?
    end
  end

  def has_child?
    Article.exists?(parent_id: self.id)
  end

  attr_accessor :draft, :keywords

  has_state(:state,
            valid_states: [:new, :draft, :publication_pending, :just_published, :published, :just_withdrawn, :withdrawn],
            initial_state: :new,
            handles: [:withdraw, :post_trigger, :send_pings, :send_notifications, :published_at=, :just_published?])

  include Article::States

  class << self
    def last_draft(article_id)
      article = Article.find(article_id)
      while article.has_child?
        article = Article.child_of(article.id).first
      end
      article
    end

    def search_with_pagination(search_hash, paginate_hash)
      state = (search_hash[:state] && ["no_draft", "drafts", "published", "withdrawn", "pending"].include?(search_hash[:state])) ? search_hash[:state] : 'no_draft'

      result = send(state)

      if search_hash[:searchstring].present?
        result = result.where("LOWER(body) LIKE ? OR LOWER(extended) LIKE ? OR LOWER(title) LIKE ?",
                               "%#{search_hash[:searchstring].downcase}%",
                               "%#{search_hash[:searchstring].downcase}%",
                               "%#{search_hash[:searchstring].downcase}%")
      end

      if search_hash[:published_at].present?
        result = result.where("published_at LIKE ?", "#{search_hash[:published_at]}%")
      end

      if search_hash[:user_id].present? && search_hash[:user_id].to_i > 0
        result = result.where(user_id: search_hash[:user_id])
      end

      if search_hash[:category] && search_hash[:category].to_i > 0
        result = result.category(search_hash[:category])
      end

      result.page(paginate_hash[:page]).per(paginate_hash[:per_page])
    end
  end

  def year_url
    published_at.year.to_s
  end

  def month_url
    sprintf("%.2d", published_at.month)
  end

  def day_url
    sprintf("%.2d", published_at.day)
  end

  def title_url
    # ERB::Util.url_encode encodes spaces as %20, then restore + signs
    ERB::Util.url_encode(permalink.to_s).gsub('%2B', '+')
  end

  def permalink_url_options(nesting = false)
    format_url = blog.permalink_format.dup
    format_url.gsub!('%year%', year_url)
    format_url.gsub!('%month%', month_url)
    format_url.gsub!('%day%', day_url)
    format_url.gsub!('%title%', title_url)
    format_url[0, 1] == '/' ? format_url[1..-1] : format_url
  end

  def permalink_url(anchor = nil, only_path = false)
    @cached_permalink_url ||= {}
    @cached_permalink_url["#{anchor}#{only_path}"] ||= blog.url_for(permalink_url_options, anchor: anchor, only_path: only_path)
  end

  def param_array
    @param_array ||= [published_at.year, sprintf('%.2d', published_at.month), sprintf('%.2d', published_at.day), permalink]
  end

  def to_param
    param_array
  end

  def trackback_url
    blog.url_for("trackbacks?article_id=#{self.id}", only_path: false)
  end

  def permalink_by_format(format = nil)
    return permalink_url if format.nil?
    return feed_url(:rss) if format.to_sym == :rss
    return feed_url(:atom) if format.to_sym == :atom
    raise UnSupportedFormat
  end

  def comment_url
    blog.url_for("comments?article_id=#{self.id}", only_path: false)
  end

  def preview_comment_url
    blog.url_for("comments/preview?article_id=#{self.id}", only_path: false)
  end

  def feed_url(format = :rss20)
    format_extension = format.to_s.gsub(/\d/, '')
    permalink_url + ".#{format_extension}"
  end

  def edit_url
    blog.url_for("admin/content/edit/#{id}")
  end

  def delete_url
    blog.url_for("admin/content/destroy/#{id}")
  end

  def html_urls
    urls = []
    html.to_s.gsub(/<a\s+[^>]*>/) do |tag|
      urls.push($2.strip) if tag =~ /\bhref=(["']?)([^ >"]+)\1/
    end
    urls.uniq
  end

  def really_send_pings(serverurl = blog.base_url, articleurl = nil)
    return unless blog.send_outbound_pings
    articleurl ||= permalink_url(nil)
    weblogupdatesping_urls = blog.ping_urls.gsub(/ +/, '').split(/[\n\r]+/).map(&:strip)
    pingback_or_trackback_urls = self.html_urls
    ping_urls = weblogupdatesping_urls + pingback_or_trackback_urls
    existing_ping_urls = pings.collect { |p| p.url }

    ping_urls.uniq.each do |url|
      begin
        unless existing_ping_urls.include?(url)
          ping = pings.build("url" => url)
          if weblogupdatesping_urls.include?(url)
            ping.send_weblogupdatesping(serverurl, articleurl)
          elsif pingback_or_trackback_urls.include?(url)
            ping.send_pingback_or_trackback(articleurl)
          end
        end
      rescue Exception => e
        logger.error(e)
      end
    end
  end

  def next
    self.class.where('published_at > ?', published_at).order('published_at asc').first
  end

  def previous
    self.class.where('published_at < ?', published_at).order('published_at desc').first
  end

  def self.count_by_date(year, month = nil, day = nil, limit = nil)
    if !year.blank?
      where(published_at: time_delta(year, month, day), published: true).count
    else
      where(published: true).count
    end
  end

  def self.find_by_published_at
    super(:published_at)
  end

  def self.get_or_build_article(id = nil)
    return Article.find(id) if id
    Article.new.tap do |art|
      art.allow_comments = art.blog.default_allow_comments
      art.allow_pings = art.blog.default_allow_pings
      art.text_filter = art.blog.text_filter
      art.old_permalink = art.permalink_url unless art.permalink.blank?
      art.published = true
    end
  end

  def self.find_by_permalink(params)
    date_range = self.time_delta(params[:year], params[:month], params[:day])
    req_params = {}
    req_params[:permalink] = params[:title] if params[:title]
    req_params[:published_at] = date_range if date_range
    return nil if req_params.empty?

    article = published.find_by(req_params)
    return article if article

    if params[:title]
      req_params[:permalink] = CGI.escape(params[:title])
      article = published.find_by(req_params)
      return article if article
    end

    raise ActiveRecord::RecordNotFound
  end

  def self.find_by_params_hash(params = {})
    params[:title] ||= params[:article_id]
    find_by_permalink(params)
  end

  def self.search(query, args = {})
    query_s = query.to_s.strip
    if !query_s.empty? && args.empty?
      Article.searchstring(query)
    elsif !query_s.empty? && !args.empty?
      Article.searchstring(query).page(args[:page]).per(args[:per])
    else
      []
    end
  end

  def keywords_to_tags
    Article.transaction do
      tags.clear
      tags << keywords.to_s.scan(/((['"]).*?\2|[\.\w]+)/).collect { |x| x.first.tr("\"'", '') }.uniq.map { |tagword| Tag.get(tagword) }
    end
  end

  def interested_users
    User.where(notify_on_new_articles: true)
  end

  def notify_user_via_email(user)
    EmailNotify.send_article(self, user) if user.notify_via_email?
  end

  def comments_closed?
    !(allow_comments? && in_feedback_window?)
  end

  def pings_closed?
    !(allow_pings? && in_feedback_window?)
  end

  def in_feedback_window?
    self.blog.sp_article_auto_close.zero? || self.published_at.to_i > self.blog.sp_article_auto_close.days.ago.to_i
  end

  def cast_to_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def published=(newval)
    state.published = cast_to_boolean(newval)
  end

  def content_fields
    [:body, :extended]
  end

  def body_and_extended
    extended.blank? ? body : body + "\n<!--more-->\n" + extended
  end

  def body_and_extended=(value)
    parts = value.split(/\n?<!--more-->\n?/, 2)
    self.body = parts[0]
    self.extended = parts[1] || ''
  end

  def link_to_author?
    !user&.email.blank? && blog.link_to_author
  end

  def password_protected?
    !password.blank?
  end

  def add_comment(params)
    comments.build(params)
  end

  def add_category(category, is_primary = false)
    self.categorizations.build(category: category, is_primary: is_primary)
  end

  def access_by?(user)
    user.admin? || user_id == user.id
  end

  protected

  def set_published_at
    self[:published_at] = self.created_at || Time.now if self.published && self[:published_at].nil?
  end

  def ensure_settings_type
    password.blank? if settings.is_a?(String)
  end

  def set_defaults
    if self.attributes.include?("permalink") && (self.permalink.blank? || self.permalink.to_s =~ /article-draft/ || self.state == "draft")
      set_permalink
    end
    self.allow_comments = blog.default_allow_comments if blog && self.allow_comments.nil?
    self.allow_pings = blog.default_allow_pings if blog && self.allow_pings.nil?
    true
  end

  def add_notifications
    users = interested_users.to_a
    users << self.user if self.user&.notify_watch_my_articles? rescue false
    self.notify_users = users.uniq
  end

  def self.time_delta(year = nil, month = nil, day = nil)
    return nil if year.nil? && month.nil? && day.nil?
    from = Time.utc(year, month || 1, day || 1)
    to = from.next_year
    to = from.next_month unless month.blank?
    to = from + 1.day unless day.blank?
    to = to - 1
    from..to
  end
end
