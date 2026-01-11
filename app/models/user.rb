# frozen_string_literal: true

require 'digest/sha1'

# Typo user.
class User < ActiveRecord::Base
  include ConfigManager

  belongs_to :profile, optional: true
  belongs_to :text_filter, optional: true

  delegate :name, to: :text_filter, prefix: true, allow_nil: true
  delegate :label, to: :profile, prefix: true, allow_nil: true

  has_many :notifications, foreign_key: 'notify_user_id'
  has_many :notify_contents, -> { distinct }, through: :notifications, source: 'notify_content'
  has_many :articles, -> { order('created_at DESC') }

  serialize :settings, coder: YAML, type: Hash

  # Settings
  setting :notify_watch_my_articles,   :boolean, true
  setting :editor,                     :string, 'visual'
  setting :firstname,                  :string, ''
  setting :lastname,                   :string, ''
  setting :nickname,                   :string, ''
  setting :description,                :string, ''
  setting :url,                        :string, ''
  setting :msn,                        :string, ''
  setting :aim,                        :string, ''
  setting :yahoo,                      :string, ''
  setting :twitter,                    :string, ''
  setting :jabber,                     :string, ''
  setting :show_url,                   :boolean, false
  setting :show_msn,                   :boolean, false
  setting :show_aim,                   :boolean, false
  setting :show_yahoo,                 :boolean, false
  setting :show_twitter,               :boolean, false
  setting :show_jabber,                :boolean, false
  setting :admin_theme,                :string,  'blue'

  class_attribute :salt

  def self.salt
    '20ac4d290c2293702c64b3b287ae5ea79b26a5c1'
  end

  attr_accessor :last_venue

  def initialize(*args)
    # Handle ActionController::Parameters for Rails 7 compatibility
    args[0] = args.first.to_unsafe_h if args.first.is_a?(ActionController::Parameters)
    super
    self.settings ||= {}
  end

  def self.authenticate(login, pass)
    find_by(login: login, password: password_hash(pass), state: 'active')
  end

  def update_connection_time
    self.last_venue = last_connection
    self.last_connection = Time.now
    save
  end

  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token = Digest::SHA1.hexdigest("#{email}--#{remember_token_expires_at}")
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token = nil
    save(validate: false)
  end

  def permalink_url(_anchor = nil, only_path = false)
    blog = Blog.default
    blog.url_for(
      controller: 'authors',
      action: 'show',
      id: login,
      only_path: only_path
    )
  end

  def self.authenticate?(login, pass)
    user = authenticate(login, pass)
    return false if user.nil?
    return true if user.login == login

    false
  end

  def self.find_by_permalink(permalink)
    find_by(login: permalink).tap do |user|
      raise ActiveRecord::RecordNotFound unless user
    end
  end

  def project_modules
    profile&.project_modules || []
  end

  # Generate Methods from AccessControl roles
  AccessControl.roles.each do |role|
    define_method "#{role.to_s.downcase}?" do
      profile&.label.to_s.downcase == role.to_s.downcase
    end
  end

  def self.to_prefix
    'author'
  end

  def simple_editor?
    editor == 'simple'
  end

  attr_writer :password

  def password(cleartext = nil)
    if cleartext
      @password.to_s
    else
      @password || read_attribute('password')
    end
  end

  def article_counter
    articles.size
  end

  def display_name
    name
  end

  def name
    self[:name].presence || "#{firstname} #{lastname}".strip.presence || login
  end

  def permalink
    login
  end

  def to_param
    permalink
  end

  def admin?
    profile&.label == Profile::ADMIN
  end

  protected

  def self.password_hash(pass) # rubocop:disable Lint/IneffectiveAccessModifier
    Digest::SHA1.hexdigest("#{salt}--#{pass}--")
  end

  def password_hash(pass)
    self.class.password_hash(pass)
  end

  before_create :crypt_password

  def crypt_password
    send_create_notification
    write_attribute 'password', password_hash(password(true))
    @password = nil
  end

  before_update :crypt_unless_empty

  def crypt_unless_empty
    if password(true).empty?
      user = self.class.find(id)
      write_attribute 'password', user.password
    else
      crypt_password
    end
  end

  before_validation :set_default_profile

  def set_default_profile
    self.profile ||= if User.none?
                       Profile.find_by(label: 'admin')
                     else
                       Profile.find_by(label: 'contributor')
                     end
  end

  validates :login, uniqueness: { on: :create }
  validates :email, uniqueness: { on: :create }
  validates :password, length: { within: 5..40 }, if: lambda {
    read_attribute('password').nil? || password.to_s.length.positive?
  }
  validates :login, presence: true
  validates :email, presence: true
  validates :password, confirmation: true
  validates :login, length: { within: 3..40 }

  private

  def send_create_notification
    email_notification = NotificationMailer.notif_user(self)
    EmailNotify.send_message(self, email_notification)
  rescue StandardError => e
    logger.error "Unable to send notification of create user email: #{e.inspect}"
  end
end
