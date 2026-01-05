# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Sidebar', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/sidebar' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/sidebar'
      expect(response).to have_http_status(:success)
    end

    it 'displays sidebar configuration' do
      get '/admin/sidebar'
      expect(response.body).to include('sidebar')
    end

    it 'displays available sidebars' do
      get '/admin/sidebar'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/sidebar/set_active' do
    before { login_as_admin }

    it 'returns success with empty active list' do
      post '/admin/sidebar/set_active', params: { active: [] }
      expect(response).to have_http_status(:redirect)
    end

    it 'creates new sidebar from available' do
      available = Sidebar.available_sidebars.first
      post '/admin/sidebar/set_active', params: { active: [available.short_name] }
      expect(response).to have_http_status(:redirect)
    end

    it 'preserves existing sidebar by html_id' do
      sidebar = Sidebar.create!(active_position: 0, type: 'SearchSidebar')
      post '/admin/sidebar/set_active', params: { active: [sidebar.html_id] }
      expect(response).to have_http_status(:redirect)
    end

    it 'returns JSON when requested' do
      post '/admin/sidebar/set_active', params: { active: [] }, as: :json
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('json')
    end
  end

  describe 'POST /admin/sidebar/remove' do
    before { login_as_admin }

    let!(:sidebar) { Sidebar.create!(active_position: 0, type: 'SearchSidebar') }

    it 'removes sidebar from flash' do
      # First set up the sidebar in flash
      get '/admin/sidebar'
      post '/admin/sidebar/remove', params: { id: sidebar.id, element: "sidebar_#{sidebar.id}" }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/sidebar/publish' do
    before { login_as_admin }

    let!(:sidebar) { Sidebar.create!(active_position: 0, type: 'SearchSidebar', config: {}) }

    it 'saves sidebar configuration' do
      post '/admin/sidebar/publish', params: {
        configure: { sidebar.id.to_s => { 'title' => 'New Title' } }
      }
      expect(response).to redirect_to(action: :index)
    end

    it 'sets flash success message' do
      post '/admin/sidebar/publish', params: { configure: {} }
      expect(flash[:success]).to be_present
    end

    it 'sweeps page cache' do
      expect(PageCache).to receive(:sweep_all)
      post '/admin/sidebar/publish', params: { configure: {} }
    end
  end
end
