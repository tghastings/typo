# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Categories', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/categories' do
    before { login_as_admin }

    it 'redirects to new page' do
      get '/admin/categories'
      expect(response).to redirect_to('/admin/categories/new')
    end
  end

  describe 'GET /admin/categories/new' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/categories/new'
      expect(response).to have_http_status(:success)
    end

    it 'displays existing categories' do
      create(:category, name: 'Technology')
      get '/admin/categories/new'
      expect(response.body).to include('Technology')
    end
  end

  describe 'POST /admin/categories/new' do
    before { login_as_admin }

    it 'creates category' do
      expect {
        post '/admin/categories/new', params: { category: { name: 'New Category' } }
      }.to change(Category, :count).by(1)
    end

    it 'redirects to new page after create' do
      post '/admin/categories/new', params: { category: { name: 'New Category' } }
      expect(response).to redirect_to('/admin/categories/new')
    end
  end

  describe 'GET /admin/categories/edit/:id' do
    before { login_as_admin }

    let!(:category) { create(:category) }

    it 'returns success' do
      get "/admin/categories/edit/#{category.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/categories/edit/:id' do
    before { login_as_admin }

    let!(:category) { create(:category, name: 'Old Name') }

    it 'updates category' do
      post "/admin/categories/edit/#{category.id}", params: { category: { name: 'New Name' } }
      expect(category.reload.name).to eq('New Name')
    end
  end

  describe 'POST /admin/categories/destroy/:id' do
    before { login_as_admin }

    let!(:category) { create(:category) }

    it 'deletes category' do
      expect {
        post "/admin/categories/destroy/#{category.id}"
      }.to change(Category, :count).by(-1)
    end
  end
end
