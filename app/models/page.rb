# frozen_string_literal: true

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
      errors.add(:redirect_url, 'must be a valid URL starting with http:// or https://') unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
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
    self.name = title.to_permalink if name.blank?
  end

  def initialize(*args)
    # Handle ActionController::Parameters for Rails 7 compatibility
    args[0] = args.first.to_unsafe_h if args.first.is_a?(ActionController::Parameters)
    super
    # Yes, this is weird - PDC
    begin
      self.settings ||= {}
    rescue Exception
      self.settings = {}
    end
  end

  content_fields :body

  def self.default_order
    'name ASC'
  end

  def self.search_paginate(search_hash, paginate_hash)
    # Build scope chain without using eval
    scope = Page.all
    scope = apply_search_filters(scope, search_hash)
    scope.page(paginate_hash[:page]).per(paginate_hash[:per_page])
  end

  def self.apply_search_filters(scope, search_hash)
    search_hash ||= {}

    scope = scope.searchstring(search_hash[:searchstring]) if search_hash[:searchstring].present?

    scope = scope.published_at_like(search_hash[:published_at]) if search_hash[:published_at] && search_hash[:published_at] =~ /\d{4}-\d{2}/

    scope = scope.user_id(search_hash[:user_id]) if search_hash[:user_id]&.to_i&.positive?

    if search_hash[:published]
      scope = scope.published if search_hash[:published].to_s == '1'
      scope = scope.not_published if search_hash[:published].to_s == '0'
    end

    scope
  end

  def permalink_url(anchor = nil, only_path = false)
    blog.url_for(
      controller: '/articles',
      action: 'view_page',
      name: name,
      anchor: anchor,
      only_path: only_path
    )
  end

  def self.find_by_published_at
    super(:created_at)
  end
end
