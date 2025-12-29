source 'https://rubygems.org'

gem 'rails', '~> 7.0.8'

# Web server
gem 'puma'

# Database
gem 'sqlite3', '~> 1.4'

group :production do
  gem 'pg', '~> 1.5'
end

# Core dependencies
gem 'rexml'  # Required in Ruby 3+
gem 'htmlentities'
gem 'bluecloth', '~> 2.2'
gem 'coderay', '~> 1.1'
gem 'kaminari'
gem 'RedCloth', '~> 4.3'
gem 'addressable', '~> 2.8', :require => 'addressable/uri'
gem 'mini_magick', '~> 4.12', :require => 'mini_magick'
gem 'uuidtools', '~> 2.2'
gem 'flickraw-cached'
gem 'rubypants', '~> 0.7'
gem 'rake'
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'recaptcha', '~> 5.0'
gem 'rails_autolink'  # Provides auto_link helper removed in Rails 4

# Asset pipeline
gem 'sprockets-rails'
gem 'sassc-rails'

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
  gem 'debug'
  gem 'xmlrpc'  # Required for ping/XML-RPC tests in Ruby 3+
end

group :development do
  gem 'listen'
end
