# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'rspec/collection_matchers'
require 'factory_bot'
require 'rexml/document'
require 'capybara/rspec'
require 'database_cleaner/active_record'

# Reset and load factories to avoid duplicate registration
FactoryBot.definition_file_paths = [File.join(Rails.root, 'spec', 'factories')]
FactoryBot.reload

# Backward compatibility: Factory alias for FactoryBot
Factory = FactoryBot

# Backward compatibility: Factory() function shorthand for Factory.create()
def Factory(name, *)
  FactoryBot.create(name, *)
end

# Backward compatibility: Old ActiveRecord find syntax
# Model.find(:first) -> Model.first
# Model.find(:all) -> Model.all
# Model.find(:first, :conditions => {...}) -> Model.where({...}).first
module ActiveRecordFindBackwardCompat
  def find(*args)
    return super if args.first.is_a?(Integer) || (args.first.is_a?(String) && args.first !~ /^(first|all|last)$/)

    type = args.shift
    options = args.first || {}

    scope = all # Start with a relation, not the class
    if options[:conditions]
      conditions = options[:conditions]
      scope = if conditions.is_a?(Array)
                scope.where(conditions[0], *conditions[1..])
              elsif conditions.is_a?(Hash)
                scope.where(conditions)
              else
                scope.where(conditions)
              end
    end
    scope = scope.order(options[:order]) if options[:order]
    scope = scope.limit(options[:limit]) if options[:limit]
    scope = scope.includes(options[:include]) if options[:include]

    case type.to_s
    when 'first' then scope.first
    when 'last' then scope.last
    when 'all' then scope # Return the relation, not an array
    else super(type, *args)
    end
  end
end

ActiveRecord::Base.extend(ActiveRecordFindBackwardCompat)

# Backward compatibility: Dynamic finders like find_or_create_by_name, find_by_name, find_all_by_*
module DynamicFindersBackwardCompat
  def method_missing(method_name, *args, &)
    case method_name.to_s
    when /^find_or_create_by_(.+)$/
      attributes = ::Regexp.last_match(1).split('_and_')
      options = args.extract_options!
      conditions = attributes.zip(args).to_h
      record = where(conditions).first
      record || create!(options.merge(conditions))
    when /^find_by_(.+)$/
      attributes = ::Regexp.last_match(1).split('_and_')
      conditions = attributes.zip(args).to_h
      where(conditions).first
    when /^find_all_by_(.+)$/
      attributes = ::Regexp.last_match(1).split('_and_')
      conditions = attributes.zip(args).to_h
      where(conditions).to_a
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s =~ /^(find_or_create_by_|find_by_|find_all_by_)/ || super
  end
end

ActiveRecord::Base.extend(DynamicFindersBackwardCompat)
class User
  def send_create_notification; end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Exclude mocks directory for now as it will be loaded conditionally
Dir[Rails.root.join('spec/support/**/*.rb')].reject { |f| f.include?('/mocks/') }.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = false # Use DatabaseCleaner instead
  config.include FactoryBot::Syntax::Methods
  config.render_views

  # DatabaseCleaner configuration
  config.before(:suite) do
    # Clean out seed data before running tests
    DatabaseCleaner.clean_with(:truncation)

    # Load HTTP mocks for unit/integration tests
    Dir[Rails.root.join('spec/support/mocks/*.rb')].each { |f| require f } unless ENV['SKIP_HTTP_MOCKS']
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :request) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each) do
    Localization.lang = :default

    # Ensure essential database records exist for each test
    FactoryBot.create(:textile) unless TextFilter.find_by(name: 'textile')
    FactoryBot.create(:markdown) unless TextFilter.find_by(name: 'markdown')
    FactoryBot.create(:none_filter) unless TextFilter.find_by(name: 'none')

    FactoryBot.create(:profile_admin) unless Profile.find_by(label: 'admin')
    FactoryBot.create(:profile_publisher) unless Profile.find_by(label: 'publisher')
    FactoryBot.create(:profile_contributor) unless Profile.find_by(label: 'contributor')
  end

  # Disable deprecated should syntax warnings
  config.expect_with :rspec do |expectations|
    expectations.syntax = %i[should expect]
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = %i[should expect]
  end

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Enable Nokogiri-based selector matchers for controller and view specs
  config.include(Module.new do
    require 'nokogiri'

    def page
      if defined?(response)
        @page ||= Nokogiri::HTML(response.body)
      elsif defined?(rendered)
        @page ||= Nokogiri::HTML(rendered)
      end
    end

    # Override have_selector to work with controller response or view rendered using Nokogiri
    def have_selector(*args)
      selector = args[0]
      options = args[1] || {}

      RSpec::Matchers.define :have_selector_in_response do |css_selector, opts|
        match do |target|
          # Handle both controller response and view rendered
          html = if target.respond_to?(:body)
                   target.body
                 elsif target.is_a?(String)
                   target
                 elsif defined?(rendered)
                   rendered
                 elsif defined?(response)
                   response.body
                 else
                   target.to_s
                 end

          doc = Nokogiri::HTML(html)
          elements = doc.css(css_selector)

          return false if elements.empty?

          # Check :content option if provided
          if opts[:content]
            elements.any? { |el| el.text.include?(opts[:content]) }
          elsif opts[:href]
            elements.any? { |el| el[:href] == opts[:href] }
          else
            true
          end
        end

        failure_message do |_target|
          if opts[:content]
            "expected to find css #{css_selector.inspect} with content #{opts[:content].inspect} but there were no matches"
          elsif opts[:href]
            "expected to find css #{css_selector.inspect} with href #{opts[:href].inspect} but there were no matches"
          else
            "expected to find css #{css_selector.inspect} but there were no matches"
          end
        end
      end
      have_selector_in_response(selector, options)
    end

    # Backward compatibility: be_success -> be_successful
    RSpec::Matchers.define :be_success do
      match(&:successful?)
    end
  end, type: :controller)

  # Include the same matcher for view specs
  config.include(Module.new do
    require 'nokogiri'

    def have_selector(*args)
      selector = args[0]
      options = args[1] || {}

      RSpec::Matchers.define :have_selector_in_view do |css_selector, opts|
        match do |target|
          html = target.is_a?(String) ? target : rendered
          doc = Nokogiri::HTML(html)
          elements = doc.css(css_selector)

          return false if elements.empty?

          if opts[:content]
            elements.any? { |el| el.text.include?(opts[:content]) }
          elsif opts[:href]
            elements.any? { |el| el[:href] == opts[:href] }
          else
            true
          end
        end

        failure_message do |_target|
          if opts[:content]
            "expected to find css #{css_selector.inspect} with content #{opts[:content].inspect} but there were no matches"
          elsif opts[:href]
            "expected to find css #{css_selector.inspect} with href #{opts[:href].inspect} but there were no matches"
          else
            "expected to find css #{css_selector.inspect} but there were no matches"
          end
        end
      end
      have_selector_in_view(selector, options)
    end
  end, type: :view)

  # Backward compatibility: mock -> double
  config.include(Module.new do
    def mock(*, &)
      double(*, &)
    end

    # Backward compatibility: mock_model (removed in rspec-rails 4+)
    def mock_model(model_class, stubs = {})
      model = double("#{model_class.name}_#{object_id}", stubs.reverse_merge(
                                                           to_param: '1',
                                                           to_key: nil,
                                                           to_model: nil,
                                                           model_name: model_class.model_name,
                                                           persisted?: false,
                                                           destroyed?: false,
                                                           marked_for_destruction?: false,
                                                           new_record?: true,
                                                           id: nil
                                                         ))
      # Allow is_a? to accept any class/symbol and return appropriate values
      allow(model).to receive(:is_a?) do |klass|
        klass == model_class || klass == model_class.superclass
      end
      allow(model).to receive(:kind_of?) do |klass|
        klass == model_class || klass == model_class.superclass
      end
      allow(model).to receive(:instance_of?).with(model_class).and_return(false)
      allow(model).to receive(:class).and_return(model_class)
      # Rails 7 compatibility: stub _read_attribute for internal ActiveRecord calls
      allow(model).to receive(:_read_attribute) do |attr_name|
        stubs[attr_name.to_sym] || stubs[attr_name.to_s]
      end
      model
    end

    # Backward compatibility: xhr method (removed in Rails 7)
    def xhr(method, action, params = {}, session = nil, flash = nil)
      options = { params: params, xhr: true }
      options[:session] = session if session
      options[:flash] = flash if flash
      # Bypass the backward compat wrapper by calling *_without_backward_compat directly
      send("#{method}_without_backward_compat", action, **options)
    end
  end)

  # Include Minitest assertions for backward compatibility
  config.include(Module.new do
    def assert(value, message = nil)
      expect(value).to be_truthy, message
    end

    def assert_equal(expected, actual, message = nil)
      expect(actual).to eq(expected), message
    end

    def assert_not_equal(expected, actual, message = nil)
      expect(actual).not_to eq(expected), message
    end

    def assert_nil(value, message = nil)
      expect(value).to be_nil, message
    end

    def assert_not_nil(value, message = nil)
      expect(value).not_to be_nil, message
    end

    def assert_match(pattern, string, message = nil)
      expect(string).to match(pattern), message
    end

    def assert_no_match(pattern, string, message = nil)
      expect(string).not_to match(pattern), message
    end

    def assert_raise(exception_class, message = nil, &)
      expect(&).to raise_error(exception_class), message
    end
    alias_method :assert_raises, :assert_raise

    def assert_nothing_raised(message = nil, &)
      expect(&).not_to raise_error, message
    end

    def assert_respond_to(object, method, message = nil)
      expect(object).to respond_to(method), message
    end

    def assert_includes(collection, item, message = nil)
      expect(collection).to include(item), message
    end

    def assert_empty(collection, message = nil)
      expect(collection).to be_empty, message
    end

    def assert_instance_of(klass, object, message = nil)
      expect(object).to be_an_instance_of(klass), message
    end

    def assert_kind_of(klass, object, message = nil)
      expect(object).to be_a_kind_of(klass), message
    end

    def refute(value, message = nil)
      expect(value).to be_falsey, message
    end
  end)
end

# Backward compatibility for old controller test syntax
# Rails 7 requires: get :action, params: {...}
# Old syntax was: get :action, {...}
module ActionController
  class TestCase
    module Behavior
      %w[get post patch put head delete].each do |method|
        define_method("#{method}_with_backward_compat") do |action, *args|
          # Handle case with no params at all
          if args.empty?
            send("#{method}_without_backward_compat", action, params: {})
          elsif args.first.is_a?(Hash) && !args.first.key?(:params) && !args.first.key?(:session) && !args.first.key?(:flash)
            # Old style: post :action, {:key => :value}
            # Convert to new style: post :action, params: {:key => :value}
            params = args.first
            options = args[1] || {}
            # Don't force format unless explicitly requested - let routes handle it
            send("#{method}_without_backward_compat", action, params: params, **options)
          else
            # Already new style - just pass through
            send("#{method}_without_backward_compat", action, *args)
          end
        end
        alias_method "#{method}_without_backward_compat", method
        alias_method method, "#{method}_with_backward_compat"
      end
    end
  end
end

def define_spec_public_cache_directory
  ActionController::Base.page_cache_directory = File.join(Rails.root, 'spec', 'public')
  return if File.exist? ActionController::Base.page_cache_directory

  FileUtils.mkdir_p ActionController::Base.page_cache_directory
end

def path_for_file_in_spec_public_cache_directory(file)
  define_spec_public_cache_directory
  File.join(ActionController::Base.page_cache_directory, file)
end

def create_file_in_spec_public_cache_directory(file)
  file_path = path_for_file_in_spec_public_cache_directory(file)
  File.open(file_path, 'a').close
  file_path
end

def assert_xml(xml)
  assert_nothing_raised do
    assert REXML::Document.new(xml)
  end
end

def assert_atom10(feed, count)
  doc = Nokogiri::XML.parse(feed)
  root = doc.css(':root').first
  root.name.should
  root.namespace.href.should
  root.css('entry').count.should == count
end

def assert_rss20(feed, count)
  doc = Nokogiri::XML.parse(feed)
  root = doc.css(':root').first
  root.name.should
  root['version'].should
  root.css('channel item').count.should == count
end

def stub_default_blog
  blog = Blog.new(base_url: 'http://myblog.net', blog_name: 'Test Blog', text_filter: 'textile')
  allow(view).to receive(:this_blog).and_return(blog)
  allow(Blog).to receive(:default).and_return(blog)
  blog
end

def stub_full_article(time = Time.now)
  author = build(:user, name: 'User Name')
  textile_filter = TextFilter.find_by(name: 'textile') || TextFilter.find_by(name: 'none')

  a = build(:article, published_at: time, user: author,
                      created_at: time, updated_at: time,
                      title: 'Foo Bar', permalink: 'foo-bar',
                      guid: time.hash.to_s,
                      text_filter_id: textile_filter&.id)
  allow(a).to receive(:categories).and_return([build(:category)])
  allow(a).to receive(:published_comments).and_return([])
  allow(a).to receive(:resources).and_return([build(:resource)])
  allow(a).to receive(:tags).and_return([build(:tag)])
  a
end

# test standard view and all themes
def with_each_theme
  yield nil, ''
  Dir.new(File.join(Rails.root.to_s, 'themes')).each do |theme|
    next if theme =~ /\.\.?/

    view_path = "#{Rails.root}/themes/#{theme}/views"
    require "#{Rails.root}/themes/#{theme}/helpers/theme_helper.rb" if File.exist?("#{Rails.root}/themes/#{theme}/helpers/theme_helper.rb")
    yield theme, view_path
  end
end

# This test now has optional support for validating the generated RSS feeds.
# Since Ruby doesn't have a RSS/Atom validator, I'm using the Python source
# for http://feedvalidator.org and calling it via 'system'.
#
# To install the validator, download the source from
# http://sourceforge.net/cvs/?group_id=99943
# Then copy src/feedvalidator and src/rdflib into a Python lib directory.
# Finally, copy src/demo.py into your path as 'feedvalidator', make it executable,
# and change the first line to something like '#!/usr/bin/python'.

if $validator_installed.nil?
  $validator_installed = false
  begin
    IO.popen('feedvalidator 2> /dev/null', 'r') do |pipe|
      if pipe.read =~ %r{Validating http://www.intertwingly.net/blog/index.}
        puts 'Using locally installed Python feed validator'
        $validator_installed = true
      end
    end
  rescue StandardError
    nil
  end
end

def assert_feedvalidator(rss, todo = nil)
  unless $validator_installed
    puts 'Not validating feed because no validator (feedvalidator in python) is installed'
    return
  end

  begin
    file = Tempfile.new('typo-feed-test')
    filename = file.path
    file.write(rss)
    file.close

    messages = ''

    IO.popen("feedvalidator file://#{filename}") do |pipe|
      messages = pipe.read
    end

    okay, messages = parse_validator_messages(messages)

    if todo && !ENV['RUN_TODO_TESTS']
      assert !okay, "#{messages}\nTest unexpectedly passed!\nFeed text:\n#{rss}"
    else
      assert okay, "#{messages}\nFeed text:\n#{rss}"
    end
  end
end

def parse_validator_messages(message)
  messages = message.split("\n").reject do |m|
    m =~ %r{Feeds should not be served with the "text/plain" media type} ||
      m =~ /Self reference doesn't match document location/
  end

  if messages.size > 1
    [false, messages.join("\n")]
  else
    [true, '']
  end
end

# Temporarily define #flunk until rspec-rails 2 beta 21 comes out.
# TODO: Remove this once no longer needed!
def flunk(*, &)
  assertion_delegate.flunk(*, &)
end

# Backward compatibility: stub_model replacement for modern RSpec
def stub_model(klass, attributes = {})
  instance = klass.new(attributes)
  allow(instance).to receive(:id).and_return(rand(1..1000))
  allow(instance).to receive(:new_record?).and_return(false)
  allow(instance).to receive(:persisted?).and_return(true)
  instance
end

# Add .stub and .stub! backward compatibility to objects
# Returns a wrapper that supports .and_return chain
class StubChain
  def initialize(object, method_name)
    @object = object
    @method_name = method_name
  end

  def and_return(value = nil, &)
    if block_given?
      RSpec::Mocks.allow_message(@object, @method_name, &)
    else
      RSpec::Mocks.allow_message(@object, @method_name) { value }
    end
    self
  end

  def with(*_args)
    # Ignore with() for backward compatibility
    self
  end
end

module StubBackwardCompatibility
  def stub(method_name, &)
    if block_given?
      RSpec::Mocks.allow_message(self, method_name, &)
      self
    else
      StubChain.new(self, method_name)
    end
  end

  # stub! is just an alias for stub in old RSpec
  alias stub! stub
end

Object.include(StubBackwardCompatibility)

# Make webrat's matchers treat XML like XML.
# See Webrat ticket #345.
# Solution adapted from the following patch:
# http://github.com/indirect/webrat/commit/46b8d91c962e802fbcb14ee0bcf03aab1afa180a
module Webrat # :nodoc:
  module XML # :nodoc:
    def self.document(stringlike) # :nodoc:
      return stringlike.dom if stringlike.respond_to?(:dom)

      case stringlike
      when Nokogiri::HTML::Document, Nokogiri::XML::NodeSet
        stringlike
      else
        stringlike = stringlike.body if stringlike.respond_to?(:body)

        if stringlike.to_s =~ /<\?xml/
          Nokogiri::XML(stringlike.to_s)
        else
          Nokogiri::HTML(stringlike.to_s)
        end
      end
    end
  end
end
