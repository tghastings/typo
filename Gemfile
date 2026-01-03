source 'https://rubygems.org'

gem 'rails', '~> 8.0.0'

# Web server
gem 'puma'

# Database
gem 'sqlite3', '~> 2.1'  # Rails 8 requires >= 2.1

group :production do
  gem 'pg', '~> 1.5'
end

# Core dependencies
gem 'rexml'  # Required in Ruby 3+
gem 'xmlrpc'  # Required for XML-RPC support in Ruby 3+
gem 'htmlentities'
gem 'bluecloth', '~> 2.2'
gem 'kramdown', '~> 2.4'           # Modern Markdown with fenced code blocks
gem 'kramdown-parser-gfm', '~> 1.1' # GitHub Flavored Markdown support
gem 'coderay', '~> 1.1'
gem 'kaminari'
gem 'RedCloth', '~> 4.3'
gem 'addressable', '~> 2.8', :require => 'addressable/uri'
gem 'mini_magick', '~> 4.12', :require => 'mini_magick'
gem 'uuidtools', '~> 2.2'
gem 'flickraw-cached'
gem 'rubypants', '~> 0.7'
gem 'rake'
gem 'htmlbeautifier', '~> 1.4'  # Beautiful HTML output
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'recaptcha', '~> 5.0'
gem 'rails_autolink'  # Provides auto_link helper removed in Rails 4

# Asset pipeline
gem 'sprockets-rails'
gem 'sassc-rails'

# Modern JavaScript with Turbo & Stimulus
gem 'importmap-rails', '~> 2.0'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'

# For observers (Rails 7 compatible)
gem 'rails-observers'

# Page caching (extracted from Rails 4+)
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'

group :development, :test do
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 6.0'
  gem 'rspec-collection_matchers'  # For have(n).items syntax
  gem 'rails-controller-testing'  # For render_template and assigns matchers
  gem 'simplecov', :require => false
  gem 'database_cleaner-active_record'
  gem 'capybara'
  gem 'selenium-webdriver'  # For system tests with JavaScript
  gem 'cucumber-rails', require: false
  gem 'cucumber', '~> 9.0'
  gem 'debug'
  gem 'rspec_junit_formatter'  # For CI test result uploads
end

group :development do
  gem 'listen'
end
