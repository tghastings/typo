# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Profiles', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/profiles' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/profiles'
      expect(response).to have_http_status(:success)
    end

    it 'displays user profile settings' do
      get '/admin/profiles'
      expect(response.body).to include('admin')
    end
  end

  describe 'POST /admin/profiles (update)' do
    before { login_as_admin }

    it 'updates user profile' do
      post '/admin/profiles', params: { user: { name: 'Updated Admin Name' } }
      expect(admin.reload.name).to eq('Updated Admin Name')
    end
  end
end
