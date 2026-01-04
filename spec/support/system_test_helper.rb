# frozen_string_literal: true

# System test configuration for Selenium WebDriver with Turbo support
require 'capybara/rspec'
require 'selenium-webdriver'

# Check if Chrome/Chromium is available for system tests
def chrome_available?
  return @chrome_available if defined?(@chrome_available)

  @chrome_available = begin
    # Try to find Chrome binary
    chrome_paths = [
      ENV.fetch('CHROME_BIN', nil),
      '/usr/bin/google-chrome',
      '/usr/bin/chromium-browser',
      '/usr/bin/chromium',
      `which google-chrome 2>/dev/null`.strip,
      `which chromium-browser 2>/dev/null`.strip,
      `which chromium 2>/dev/null`.strip
    ].compact.reject(&:empty?)

    chrome_paths.any? { |path| File.exist?(path) }
  rescue StandardError
    false
  end
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    skip 'System tests require Chrome/Chromium browser (not available in this environment)' unless chrome_available?

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-gpu')
      # Enable browser console logging
      options.add_option('goog:loggingPrefs', { browser: 'ALL' })
    end
  end
end

# Custom helper methods for system tests
module SystemTestHelpers
  def login_as_admin
    # Create admin user with proper profile
    admin_profile = Profile.find_by(label: 'admin') || FactoryBot.create(:profile_admin)
    @admin_user ||= FactoryBot.create(:user, profile: admin_profile, login: 'admin_test', password: 'top-secret')

    visit '/accounts/login'
    fill_in 'user_login', with: @admin_user.login
    fill_in 'user_password', with: 'top-secret'
    click_button 'Login'
    expect(page).to have_content('Logged in as')
  end

  def wait_for_turbo(timeout = 2)
    # Wait for Turbo to finish loading
    expect(page).to have_no_css('.turbo-progress-bar', wait: timeout)
  end

  def wait_for_turbo_frame(id, timeout = 2)
    # Wait for a specific turbo frame to load
    expect(page).to have_css("turbo-frame##{id}[complete]", wait: timeout)
  end
end

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
end
