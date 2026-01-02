class Page < Content
  belongs_to :user, optional: true
  validates_presence_of :title
  validates_presence_of :body, unless: :external_redirect?
  validates_uniqueness_of :name
  validate :validate_redirect_url

  def external_redirect?
    redirect_url.present?
  end

  private

  def validate_redirect_url
    return if redirect_url.blank?

    begin
      uri = URI.parse(redirect_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:redirect_url, 'must be a valid URL starting with http:// or https://')
      end
    rescue URI::InvalidURIError
      errors.add(:redirect_url, 'must be a valid URL starting with http:// or https://')
    end
  end

  public

  include ConfigManager

  serialize :settings, coder: YAML, type: Hash
  setting :password, :string, ''

  before_save :set_permalink
  after_save :shorten_url

  def set_permalink
    self.name = self.title.to_permalink if self.name.blank?
  end

  def initialize(*args)
    # Handle ActionController::Parameters for Rails 7 compatibility
    if args.first.is_a?(ActionController::Parameters)
      args[0] = args.first.to_unsafe_h
    end
    super
    # Yes, this is weird - PDC
    begin
      self.settings ||= {}
    rescue Exception => e
      self.settings = {}
    end
  end

  content_fields :body

  def self.default_order
    'name ASC'
  end

  def self.search_paginate(search_hash, paginate_hash)
    list_function = ["Page"] + function_search_no_draft(search_hash)
    paginate_hash[:order] = 'title ASC'
    list_function << "page(paginate_hash[:page])"
    list_function << "per(paginate_hash[:per_page])"

    eval(list_function.join('.'))
  end

  def permalink_url(anchor=nil, only_path=false)
    blog.url_for(
      :controller => '/articles',
      :action => 'view_page',
      :name => name,
      :anchor => anchor,
      :only_path => only_path
    )
  end

  def self.find_by_published_at
    super(:created_at)
  end
end
