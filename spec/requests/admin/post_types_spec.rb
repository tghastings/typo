# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Post Types', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/post_types' do
    before { login_as_admin }

    it 'redirects to new' do
      get '/admin/post_types'
      expect(response).to redirect_to('/admin/post_types/new')
    end
  end

  describe 'GET /admin/post_types/new' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/post_types/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/post_types/new' do
    before { login_as_admin }

    it 'creates post type' do
      expect do
        post '/admin/post_types/new', params: { post_type: { name: 'video', description: 'Video posts' } }
      end.to change(PostType, :count).by(1)
    end
  end
end
