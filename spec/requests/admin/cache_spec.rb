# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Cache', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/cache' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/cache'
      expect(response).to have_http_status(:success)
    end

    it 'displays cache management page' do
      get '/admin/cache'
      expect(response.body.downcase).to include('cache')
    end
  end

  describe 'POST /admin/cache (sweep)' do
    before { login_as_admin }

    it 'sweeps cache and returns success' do
      post '/admin/cache'
      expect(response).to have_http_status(:success)
    end

    it 'displays confirmation message' do
      post '/admin/cache'
      expect(response.body).to include('sweeped').or include('Cache')
    end
  end
end
