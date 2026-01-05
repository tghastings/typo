# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Tags', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/tags' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/tags'
      expect(response).to have_http_status(:success)
    end

    it 'displays tags' do
      create(:tag, name: 'ruby')
      get '/admin/tags'
      expect(response.body).to include('ruby')
    end
  end

  describe 'GET /admin/tags/edit/:id' do
    before { login_as_admin }

    let!(:tag) { create(:tag) }

    it 'returns success' do
      get "/admin/tags/edit/#{tag.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/tags/edit/:id' do
    before { login_as_admin }

    let!(:tag) { create(:tag, display_name: 'Old Name') }

    it 'updates tag' do
      post "/admin/tags/edit/#{tag.id}", params: { tag: { display_name: 'New Name' } }
      expect(tag.reload.display_name).to eq('New Name')
    end
  end

  describe 'POST /admin/tags/destroy/:id' do
    before { login_as_admin }

    let!(:tag) { create(:tag) }

    it 'deletes tag' do
      expect {
        post "/admin/tags/destroy/#{tag.id}"
      }.to change(Tag, :count).by(-1)
    end
  end
end
