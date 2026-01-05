# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Settings', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/settings' do
    context 'when logged in as admin' do
      before { login_as_admin }

      it 'returns success' do
        get '/admin/settings'
        expect(response).to have_http_status(:success)
      end

      it 'displays settings form' do
        get '/admin/settings'
        expect(response.body).to include('blog_name')
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        get '/admin/settings'
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end

  describe 'POST /admin/settings/update' do
    before { login_as_admin }

    it 'updates blog settings' do
      post '/admin/settings/update', params: { setting: { blog_name: 'Updated Blog Name' } }
      expect(blog.reload.blog_name).to eq('Updated Blog Name')
    end

    it 'redirects back to settings' do
      post '/admin/settings/update', params: { setting: { blog_name: 'Updated Blog Name' } }
      expect(response).to redirect_to('/admin/settings')
    end
  end
end
