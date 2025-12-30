# System test configuration for Selenium WebDriver with Turbo support
require 'capybara/rspec'
require 'selenium-webdriver'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-gpu')
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
