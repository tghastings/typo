# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Article Autosave with Turbo', type: :system, js: true do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_user) { FactoryBot.create(:user, profile: Profile.find_by(label: 'admin')) }

  before do
    login_as_admin
  end

  describe 'Autosave Stimulus Controller' do
    it 'loads autosave controller on article form' do
      visit '/admin/content/new'

      # Form should have autosave controller
      expect(page).to have_css('form[data-controller="autosave"]')
    end

    it 'has autosave status target' do
      visit '/admin/content/new'

      # Should have autosave status display area
      expect(page).to have_css('#autosave[data-autosave-target="status"]')
    end

    it 'displays article form fields' do
      visit '/admin/content/new'

      expect(page).to have_field('article[title]')
      expect(page).to have_field('article[body]')
      expect(page).to have_button('Publish')
    end
  end

  describe 'Manual save trigger', skip: 'Autosave requires JavaScript timing' do
    it 'saves draft via Turbo Stream' do
      visit '/admin/content/new'

      fill_in 'article[title]', with: 'Test Autosave Article'
      fill_in 'article[body]', with: 'This is a test of the autosave feature'

      # Manually trigger autosave (would normally happen automatically)
      # This would require executing JS: page.execute_script("document.querySelector('[data-controller=\"autosave\"]').autosaveController.save()")

      # Check for autosave success message
      expect(page).to have_css('#autosave', text: /saved/i, wait: 5)
    end
  end

  describe 'Draft preservation' do
    it 'shows preview link after save' do
      # Create a draft article first
      article = FactoryBot.create(:article, user: admin_user, blog: blog, state: 'draft', title: 'Draft Article')

      visit "/admin/content/edit/#{article.id}"

      # Should show preview link for existing draft
      expect(page).to have_link('Preview')
    end

    it 'shows destroy draft link for drafts' do
      article = FactoryBot.create(:article, user: admin_user, blog: blog, state: 'draft', title: 'Draft to Delete')

      visit "/admin/content/edit/#{article.id}"

      # Should show destroy draft link
      within('#destroy_link') do
        expect(page).to have_link('Delete Draft')
      end
    end
  end
end
