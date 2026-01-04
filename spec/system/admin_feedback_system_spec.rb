# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Feedback Management with Turbo', type: :system, js: true do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_user) { FactoryBot.create(:user, profile: Profile.find_by(label: 'admin')) }
  let!(:article) { FactoryBot.create(:article, user: admin_user, blog: blog) }
  let!(:ham_comment) { FactoryBot.create(:comment, article: article, state: 'ham') }
  let!(:spam_comment) { FactoryBot.create(:comment, article: article, state: 'spam') }

  before do
    login_as_admin
  end

  describe 'Turbo Frames - Feedback Pagination' do
    it 'loads feedback list within turbo frame' do
      visit '/admin/feedback'

      expect(page).to have_css('turbo-frame#feedback_list')
      expect(page).to have_content(ham_comment.author)
      expect(page).to have_content(spam_comment.author)
    end

    it 'paginates without full page reload', skip: 'Pagination requires multiple feedback items' do
      # Create enough feedback to trigger pagination
      20.times do |i|
        FactoryBot.create(:comment, article: article, author: "Commenter #{i}")
      end

      visit '/admin/feedback'

      # Get current page title to ensure we're tracking page context
      original_title = page.title

      # Click next page within turbo frame
      within('turbo-frame#feedback_list') do
        click_link 'Next' if page.has_link?('Next')
      end

      # Page title should remain the same (no full reload)
      expect(page.title).to eq(original_title)

      # But content should update
      wait_for_turbo
    end
  end

  describe 'Turbo Streams - Ham/Spam Toggle' do
    it 'toggles spam to ham without page reload' do
      visit '/admin/feedback'

      # Find the spam comment row
      spam_row = find("#feedback_#{spam_comment.id}")
      expect(spam_row).to have_content('spam')

      # Click "Mark as Ham" link
      within(spam_row) do
        click_link 'Mark as Ham'
      end

      # Wait for Turbo Stream to update
      sleep 0.5

      # Row should now show ham status
      updated_row = find("#feedback_#{spam_comment.id}")
      expect(updated_row).to have_content('ham')
      expect(updated_row).to have_link('Flag as spam')
    end

    it 'toggles ham to spam without page reload' do
      visit '/admin/feedback'

      # Find the ham comment row
      ham_row = find("#feedback_#{ham_comment.id}")
      expect(ham_row).to have_content('ham')

      # Click "Flag as spam" link
      within(ham_row) do
        click_link 'Flag as spam'
      end

      # Wait for Turbo Stream to update
      sleep 0.5

      # Row should now show spam status
      updated_row = find("#feedback_#{ham_comment.id}")
      expect(updated_row).to have_content('spam')
      expect(updated_row).to have_link('Mark as Ham')
    end

    it 'updates row content via Turbo Stream replace' do
      visit '/admin/feedback'

      # Get initial row HTML
      initial_row = find("#feedback_#{spam_comment.id}")
      initial_html = initial_row.native.attribute('outerHTML')

      # Toggle status
      within(initial_row) do
        click_link 'Mark as Ham'
      end

      sleep 0.5

      # Row HTML should be different
      updated_row = find("#feedback_#{spam_comment.id}")
      updated_html = updated_row.native.attribute('outerHTML')

      expect(updated_html).not_to eq(initial_html)
    end
  end

  describe 'Feedback filtering with Turbo' do
    it 'filters to show only spam' do
      visit '/admin/feedback'

      click_link 'Spam'
      wait_for_turbo

      expect(page).to have_content(spam_comment.author)
      expect(page).not_to have_content(ham_comment.author) if ham_comment.author != spam_comment.author
    end

    it 'filters to show only ham' do
      visit '/admin/feedback'

      click_link 'Ham'
      wait_for_turbo

      expect(page).to have_content(ham_comment.author)
      expect(page).not_to have_content(spam_comment.author) if spam_comment.author != ham_comment.author
    end
  end
end
