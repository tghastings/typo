# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown Editor', type: :system, js: true do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_user) { FactoryBot.create(:user, profile: Profile.find_by(label: 'admin'), editor: 'markdown') }

  before do
    login_as_admin
  end

  describe 'Editor Loading' do
    it 'displays the markdown editor container' do
      visit '/admin/content/new'

      expect(page).to have_css('.markdown-editor-container')
      expect(page).to have_css('[data-controller="markdown-editor"]')
    end

    it 'connects the markdown-editor Stimulus controller' do
      visit '/admin/content/new'
      sleep 3 # Wait for JS to load

      # Get browser console logs
      logs = begin
        page.driver.browser.logs.get(:browser)
      rescue StandardError
        []
      end
      puts "\n=== BROWSER LOGS ==="
      logs.each { |log| puts "  [#{log.level}] #{log.message}" }
      puts "=== END LOGS ===\n"

      # Wait for Stimulus controller to connect
      expect(page).to have_css('[data-controller="markdown-editor"]', wait: 5)

      connected = page.evaluate_script(<<~JS)
        (function() {
          var el = document.querySelector('[data-controller="markdown-editor"]');
          if (!el) return 'element not found';
          if (!window.Stimulus) return 'Stimulus not loaded';
          var controller = window.Stimulus.getControllerForElementAndIdentifier(el, 'markdown-editor');
          return controller ? 'connected' : 'not connected';
        })()
      JS

      puts "Controller connection status: #{connected}"
      expect(connected).to eq('connected')
    end

    it 'removes loading message after initialization' do
      visit '/admin/content/new'

      # The loading message should be removed when editor initializes
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'displays markdown toolbar with all buttons' do
      visit '/admin/content/new'

      expect(page).to have_css('.markdown-toolbar')
      expect(page).to have_button('B')  # Bold
      expect(page).to have_button('I')  # Italic
      expect(page).to have_css('button[title*="Link"]')
      expect(page).to have_css('button[title*="Image"]')
      expect(page).to have_css('button[title*="Heading"]')
      expect(page).to have_css('button[title*="Quote"]')
    end
  end

  describe 'Editor Functionality' do
    before do
      visit '/admin/content/new'
      # Wait for editor to be ready
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'allows typing in the editor' do
      # Find the CodeMirror editor or fallback textarea
      # CodeMirror 5 uses .CodeMirror-code, fallback is .markdown-textarea
      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('# Hello World')

      # Check hidden input has the content
      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('# Hello World')
    end

    it 'syncs content to hidden form field' do
      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('Test content for syncing')

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('Test content for syncing')
    end
  end

  describe 'Toolbar Actions' do
    before do
      visit '/admin/content/new'
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'inserts bold markdown when clicking bold button' do
      find('button[title*="Bold"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('**')
    end

    it 'inserts italic markdown when clicking italic button' do
      find('button[title*="Italic"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('*')
    end

    it 'inserts heading markdown when clicking heading button' do
      find('button[title*="Heading"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('##')
    end

    it 'inserts blockquote markdown when clicking quote button' do
      find('button[title*="Quote"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('>')
    end

    it 'inserts unordered list markdown when clicking list button' do
      find('button[title*="Unordered"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('- ')
    end

    it 'inserts ordered list markdown when clicking ordered list button' do
      find('button[title*="Ordered"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('1.')
    end

    it 'inserts more divider when clicking more button' do
      find('button[title*="Read More"]').click

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('<!--more-->')
    end
  end

  describe 'Typo Macros' do
    before do
      visit '/admin/content/new'
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'has Typo code button in toolbar' do
      expect(page).to have_css('button[title*="Code"]')
    end

    it 'has Typo amazon button in toolbar' do
      expect(page).to have_css('button[title*="Amazon"]')
    end

    it 'has Typo lightbox button in toolbar' do
      expect(page).to have_css('button[title*="Lightbox"]')
    end

    it 'inserts typo:code macro with language prompt', pending: 'Requires prompt handling' do
      # This test would need to handle browser prompts
      find('button[title*="Code"]').click
      # Would need to fill in prompt for language
      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('<typo:code')
    end
  end

  describe 'Live Preview' do
    before do
      visit '/admin/content/new'
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'has a preview toggle button' do
      expect(page).to have_css('button[data-action*="togglePreview"], .preview-toggle')
    end

    it 'shows preview panel when toggled' do
      # Find and click preview toggle
      find('button[data-action*="togglePreview"], .preview-toggle').click

      expect(page).to have_css('.markdown-preview, .preview-pane')
    end

    it 'renders markdown as HTML in preview' do
      # Type some markdown first
      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('# Test Heading')

      # Toggle preview
      find('button[data-action*="togglePreview"], .preview-toggle').click

      # Check preview contains rendered HTML
      within('.markdown-preview') do
        expect(page).to have_css('h1', text: 'Test Heading')
      end
    end

    it 'updates preview after typing and toggling' do
      # Type markdown first (while editor is visible)
      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('**bold text**')

      # Toggle preview to see result
      find('button[data-action*="togglePreview"], .preview-toggle').click

      # Check preview shows rendered HTML
      within('.markdown-preview') do
        expect(page).to have_css('strong', text: 'bold text')
      end
    end
  end

  describe 'Syntax Highlighting' do
    before do
      visit '/admin/content/new'
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'loads CodeMirror with syntax highlighting' do
      # CodeMirror 5 should be loaded and create its wrapper
      expect(page).to have_css('.CodeMirror', wait: 5)
    end

    it 'highlights markdown headings' do
      # Use JavaScript to set content in CodeMirror (more reliable than send_keys)
      page.execute_script("document.querySelector('.CodeMirror').CodeMirror.setValue('# Heading')")

      # CodeMirror 5 uses .cm-header for markdown headings
      expect(page).to have_css('.cm-header', wait: 3)
    end

    it 'highlights bold syntax' do
      page.execute_script("document.querySelector('.CodeMirror').CodeMirror.setValue('**bold**')")

      # CodeMirror 5 uses .cm-strong for bold in GFM mode
      expect(page).to have_css('.cm-strong', wait: 3)
    end

    it 'shows line numbers' do
      # CodeMirror should show line numbers
      expect(page).to have_css('.CodeMirror-linenumber', wait: 5)
    end
  end

  describe 'Keyboard Shortcuts' do
    before do
      visit '/admin/content/new'
      expect(page).not_to have_css('.editor-loading', wait: 10)
    end

    it 'inserts bold with Ctrl+B' do
      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('test')
      editor_area.send_keys([:control, 'a'])  # Select all
      editor_area.send_keys([:control, 'b'])  # Bold

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('**test**')
    end

    it 'inserts italic with Ctrl+I' do
      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('test')
      editor_area.send_keys([:control, 'a'])  # Select all
      editor_area.send_keys([:control, 'i'])  # Italic

      hidden_input = find('[data-markdown-editor-target="input"]', visible: false)
      expect(hidden_input.value).to include('*test*')
    end
  end

  describe 'Pages Editor' do
    it 'uses markdown editor for pages' do
      visit '/admin/pages/new'

      expect(page).to have_css('.markdown-editor-container')
      expect(page).to have_css('[data-controller="markdown-editor"]')
    end

    it 'loads editor without errors on pages' do
      visit '/admin/pages/new'

      # Wait for editor
      expect(page).not_to have_css('.editor-loading', wait: 10)

      # Check for JS errors
      logs = page.driver.browser.logs.get(:browser)
      js_errors = logs.select { |log| log.level == 'SEVERE' }

      expect(js_errors).to be_empty, "JavaScript errors: #{js_errors.map(&:message).join(', ')}"
    end
  end

  describe 'Form Submission' do
    it 'submits article with markdown content' do
      visit '/admin/content/new'
      expect(page).not_to have_css('.editor-loading', wait: 10)

      fill_in 'article[title]', with: 'Test Article'

      editor_area = find('.CodeMirror-code, .markdown-textarea', wait: 5)
      editor_area.send_keys('# My Test Content')
      editor_area.send_keys(:enter)
      editor_area.send_keys('This is a **test** article.')

      click_button 'Publish'

      expect(page).to have_content('Article was successfully created')
      expect(Article.last.body).to include('My Test Content')
    end
  end
end
