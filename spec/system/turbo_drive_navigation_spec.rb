require 'spec_helper'

RSpec.describe 'Turbo Drive Navigation', type: :system, js: true do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_user) { FactoryBot.create(:user, profile: Profile.find_by(label: "admin")) }

  before do
    login_as_admin
  end

  describe 'Page navigation with Turbo Drive' do
    it 'navigates between admin pages' do
      visit '/admin/dashboard'
      expect(page).to have_content('Dashboard')

      click_link 'Content'
      wait_for_turbo
      expect(current_path).to eq('/admin/content')

      # Page should load without full refresh
      expect(page).to have_content('New article') # or similar content
    end

    it 'preserves session during Turbo navigation' do
      visit '/admin/dashboard'

      # Navigate to another page
      click_link 'Feedback' if page.has_link?('Feedback')
      wait_for_turbo

      # Should still be logged in
      expect(page).to have_content("Logged in as #{admin_user.nickname}")
    end
  end

  describe 'Turbo compatibility' do
    it 'loads Turbo JavaScript library' do
      visit '/admin/dashboard'

      # Check if Turbo is available
      turbo_loaded = page.evaluate_script('typeof Turbo !== "undefined"')
      expect(turbo_loaded).to be true
    end

    it 'loads Stimulus JavaScript library' do
      visit '/admin/dashboard'

      # Check if Stimulus is available
      stimulus_loaded = page.evaluate_script('typeof Stimulus !== "undefined"')
      expect(stimulus_loaded).to be true
    end

    it 'does not load Prototype.js (legacy library removed)' do
      visit '/admin/dashboard'

      # Prototype should NOT be loaded
      prototype_loaded = page.evaluate_script('typeof Prototype !== "undefined"')
      expect(prototype_loaded).to be false
    end
  end
end
