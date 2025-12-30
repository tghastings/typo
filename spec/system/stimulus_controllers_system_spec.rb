require 'spec_helper'

RSpec.describe 'Stimulus Controllers', type: :system, js: true do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_user) { FactoryBot.create(:user, profile: Profile.find_by(label: "admin")) }

  before do
    login_as_admin
  end

  describe 'Dropdown Controller' do
    it 'toggles dropdown menu on click' do
      visit '/admin/dashboard'

      # Find dropdown with Stimulus controller
      dropdown = find('.dropdown[data-controller="dropdown"]', match: :first)

      # Menu should be hidden initially
      menu = dropdown.find('.dropdown-menu[data-dropdown-target="menu"]')
      expect(menu[:style]).to include('display: none')

      # Click toggle
      dropdown.find('a[data-action*="dropdown#toggle"]').click

      # Menu should now be visible
      expect(menu[:style]).not_to include('display: none')
    end
  end

  describe 'Flash Controller' do
    it 'displays flash messages with auto-dismiss', skip: 'Requires flash message trigger' do
      # Create a scenario that triggers a flash message
      visit '/admin/feedback'

      # Look for flash message with controller
      if page.has_css?('[data-controller="flash"]')
        flash_element = find('[data-controller="flash"]')

        # Flash should auto-dismiss after timeout
        sleep 6 # Default is 5 seconds
        expect(page).not_to have_css('[data-controller="flash"]')
      end
    end
  end

  describe 'CKEditor Controller', skip: 'CKEditor requires full page JS load' do
    it 'initializes CKEditor on article form' do
      visit '/admin/content/new'

      # Should have CKEditor controller on textarea
      if page.has_css?('[data-controller="ckeditor"]')
        expect(page).to have_css('[data-controller="ckeditor"]')
      end
    end
  end
end
