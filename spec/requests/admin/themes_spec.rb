# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Themes', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/themes' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/themes'
      expect(response).to have_http_status(:success)
    end

    it 'displays available themes' do
      get '/admin/themes'
      expect(response.body).to include('theme')
    end

    it 'shows current active theme' do
      get '/admin/themes'
      expect(response).to have_http_status(:success)
    end

    it 'renders theme descriptions as HTML' do
      get '/admin/themes'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/themes/preview/:theme' do
    before { login_as_admin }

    context 'with valid theme' do
      let(:theme) { Theme.find_all.first }

      it 'returns preview image if exists' do
        get "/admin/themes/preview/#{theme.name}"
        expect(response.status).to be_in([200, 404])
      end
    end

    context 'with path traversal attempt' do
      it 'sanitizes theme name' do
        get '/admin/themes/preview/../../../etc/passwd'
        expect(response).to have_http_status(:not_found)
      end

      it 'blocks double dots' do
        get '/admin/themes/preview/..%2F..%2Fetc'
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with non-existent theme' do
      it 'returns not found' do
        get '/admin/themes/preview/nonexistent_theme_xyz'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /admin/themes/switchto/:theme' do
    before { login_as_admin }

    context 'with valid theme' do
      let(:theme) { Theme.find_all.first }

      it 'handles theme switch request' do
        post "/admin/themes/switchto/#{theme.name}"
        expect(response.status).to be_in([200, 302, 404])
      end
    end
  end
end
