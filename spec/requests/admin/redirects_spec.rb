# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Redirects', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/redirects' do
    before { login_as_admin }

    it 'redirects to new page' do
      get '/admin/redirects'
      expect(response).to redirect_to('/admin/redirects/new')
    end
  end

  describe 'GET /admin/redirects/new' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/redirects/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/redirects/new' do
    before { login_as_admin }

    it 'creates redirect' do
      expect {
        post '/admin/redirects/new', params: { redirect: { from_path: '/old', to_path: '/new' } }
      }.to change(Redirect, :count).by(1)
    end
  end

  describe 'GET /admin/redirects/edit/:id' do
    before { login_as_admin }

    let!(:redirect) { create(:redirect) }

    it 'returns success' do
      get "/admin/redirects/edit/#{redirect.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/redirects/edit/:id' do
    before { login_as_admin }

    let!(:redirect) { create(:redirect, from_path: '/old', to_path: '/new') }

    it 'updates redirect' do
      post "/admin/redirects/edit/#{redirect.id}", params: { redirect: { to_path: '/updated' } }
      expect(redirect.reload.to_path).to eq('/updated')
    end
  end

  describe 'POST /admin/redirects/destroy/:id' do
    before { login_as_admin }

    let!(:redirect) { create(:redirect) }

    it 'deletes redirect' do
      expect {
        post "/admin/redirects/destroy/#{redirect.id}"
      }.to change(Redirect, :count).by(-1)
    end
  end
end
