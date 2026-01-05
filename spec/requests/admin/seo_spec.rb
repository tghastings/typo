# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin SEO', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end


  describe 'GET /admin/seo/permalinks' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/seo/permalinks'
      expect(response).to have_http_status(:success)
    end

    context 'with standard permalink format' do
      before do
        blog.update(permalink_format: '/%year%/%month%/%day%/%title%')
      end

      it 'shows standard format option' do
        get '/admin/seo/permalinks'
        expect(response).to have_http_status(:success)
      end
    end

    context 'with custom permalink format' do
      before do
        blog.update(permalink_format: '/%category%/%title%')
      end

      it 'shows custom format' do
        get '/admin/seo/permalinks'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin/seo/permalinks' do
    before { login_as_admin }

    it 'updates permalink format' do
      post '/admin/seo/permalinks', params: {
        setting: { permalink_format: '/%year%/%month%/%title%' },
        from: 'permalinks'
      }
      expect(response).to redirect_to(action: 'permalinks')
    end

    it 'handles custom permalink format' do
      post '/admin/seo/permalinks', params: {
        setting: { permalink_format: 'custom', custom_permalink: '/%category%/%title%' },
        from: 'permalinks'
      }
      expect(blog.reload.permalink_format).to eq('/%category%/%title%')
    end
  end

  describe 'GET /admin/seo/titles' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/seo/titles'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/seo/update' do
    before { login_as_admin }

    it 'updates SEO settings' do
      post '/admin/seo/update', params: {
        setting: { meta_description: 'Test description' },
        from: 'index'
      }
      expect(response).to redirect_to(action: 'index')
    end

    it 'saves robots.txt when provided' do
      post '/admin/seo/update', params: {
        setting: { robots: "User-agent: *\nDisallow: /admin" },
        from: 'index'
      }
      expect(response).to redirect_to(action: 'index')
    end

    it 'redirects to permalinks when from=permalinks' do
      post '/admin/seo/update', params: {
        setting: { permalink_format: '/%title%' },
        from: 'permalinks'
      }
      expect(response).to redirect_to(action: 'permalinks')
    end

    it 'redirects to titles when from=titles' do
      post '/admin/seo/update', params: {
        setting: { title_prefix: 1 },
        from: 'titles'
      }
      expect(response).to redirect_to(action: 'titles')
    end

    it 'handles unknown from param' do
      post '/admin/seo/update', params: {
        setting: { meta_description: 'Test' },
        from: 'unknown'
      }
      expect(response).to redirect_to(action: 'index')
    end
  end
end
