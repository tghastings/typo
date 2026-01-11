# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Pages', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/pages' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/pages'
      expect(response).to have_http_status(:success)
    end

    it 'displays pages' do
      create(:page, title: 'About Us', user: admin)
      get '/admin/pages'
      expect(response.body).to include('About Us')
    end
  end

  describe 'GET /admin/pages/new' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/pages/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/pages/new' do
    before { login_as_admin }

    context 'with valid params' do
      let(:valid_params) do
        {
          page: {
            title: 'New Page',
            name: 'new-page',
            body: 'Page content'
          }
        }
      end

      it 'creates page' do
        expect do
          post '/admin/pages/new', params: valid_params
        end.to change(Page, :count).by(1)
      end
    end
  end

  describe 'GET /admin/pages/edit/:id' do
    before { login_as_admin }

    let!(:page) { create(:page, user: admin) }

    it 'returns success' do
      get "/admin/pages/edit/#{page.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/pages/edit/:id' do
    before { login_as_admin }

    let!(:page) { create(:page, user: admin, title: 'Old Title') }

    it 'updates page' do
      post "/admin/pages/edit/#{page.id}", params: { page: { title: 'New Title' } }
      expect(page.reload.title).to eq('New Title')
    end
  end

  describe 'POST /admin/pages/destroy/:id' do
    before { login_as_admin }

    let!(:page) { create(:page, user: admin) }

    it 'deletes page' do
      expect do
        post "/admin/pages/destroy/#{page.id}"
      end.to change(Page, :count).by(-1)
    end
  end
end
