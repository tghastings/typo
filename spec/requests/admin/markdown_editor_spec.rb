# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown Editor', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  # Preview functionality removed - we only want markdown editing, no HTML preview

  describe 'Markdown Editor Interface' do
    before { login_admin }

    it 'does not include preview pane in markdown editor' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      expect(response.body).not_to include('preview-pane')
      expect(response.body).not_to include('Preview')
    end

    it 'includes only the editor pane' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      expect(response.body).to include('editor-pane')
      expect(response.body).to include('markdown-editor')
    end

    it 'includes markdown toolbar for formatting' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      expect(response.body).to include('markdown-toolbar')
    end

    it 'does not load preview-related JavaScript' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      # Should not have preview URL
      expect(response.body).not_to include('preview-url-value')
    end
  end

  describe 'GET /admin/content/insert_editor (markdown)' do
    before { login_admin }

    it 'switches to markdown editor' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      expect(response).to be_successful
    end

    it 'updates user editor preference to markdown' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      expect(@admin.reload.editor).to eq('markdown')
    end

    it 'renders the markdown editor partial' do
      get '/admin/content/insert_editor', params: { editor: 'markdown' }
      expect(response.body).to include('markdown-editor')
    end
  end

  describe 'GET /admin/content/new with markdown editor' do
    before { login_admin }

    context 'when user prefers markdown editor' do
      before do
        @admin.editor = 'markdown'
        @admin.save(validate: false)
      end

      it 'displays markdown editor directly without tabs' do
        get '/admin/content/new'
        expect(response.body).to include('markdown-editor-container')
        # Should not have the tabs ul element for editor switching
        expect(response.body).not_to match(/<ul[^>]*class=["']tabs["'][^>]*>\s*<li[^>]*>.*?Visual/m)
        expect(response.body).not_to match(/<ul[^>]*class=["']tabs["'][^>]*>.*?<li[^>]*>.*?HTML/m)
      end

      it 'does not include visual editor div container' do
        get '/admin/content/new'
        expect(response.body).not_to match(/<div[^>]*id=["']visual_editor["']/)
      end

      it 'does not include simple/HTML editor div container' do
        get '/admin/content/new'
        expect(response.body).not_to match(/<div[^>]*id=["']simple_editor["']/)
      end

      it 'does not include quicktags toolbar' do
        get '/admin/content/new'
        expect(response.body).not_to match(/<div[^>]*id=["']quicktags["']/)
      end
    end
  end

  describe 'POST /admin/resources/upload (JSON)', skip: 'File upload tested in resources controller spec' do
    # JSON upload response is tested indirectly via existing resources controller tests
    # The markdown editor uses this endpoint for drag-and-drop image uploads
  end

  describe 'POST /admin/content/new with markdown content' do
    before { login_admin }

    it 'creates article with markdown body' do
      expect {
        post '/admin/content/new', params: {
          article: {
            title: 'Markdown Article',
            body_and_extended: '# Hello Markdown\n\nThis is **bold** and *italic*.'
          }
        }
      }.to change { Article.count }.by(1)
    end

    it 'stores raw markdown in body field' do
      post '/admin/content/new', params: {
        article: {
          title: 'Markdown Article',
          body_and_extended: '# Hello Markdown'
        }
      }
      article = Article.last
      expect(article.body).to include('# Hello Markdown')
    end
  end
end
