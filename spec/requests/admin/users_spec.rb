# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Users', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/users' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/users'
      expect(response).to have_http_status(:success)
    end

    it 'displays users list' do
      get '/admin/users'
      expect(response.body).to include('admin')
    end
  end

  describe 'GET /admin/users/new' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/users/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/users/new' do
    before do
      login_as_admin
      create(:profile_contributor, label: 'contributor')
    end

    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            login: 'newuser',
            email: 'newuser@example.com',
            password: 'password123'
          }
        }
      end

      it 'creates user' do
        expect {
          post '/admin/users/new', params: valid_params
        }.to change(User, :count).by(1)
      end
    end
  end

  describe 'GET /admin/users/edit/:id' do
    before { login_as_admin }

    it 'returns success' do
      get "/admin/users/edit/#{admin.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/users/edit/:id' do
    before { login_as_admin }

    it 'updates user' do
      post "/admin/users/edit/#{admin.id}", params: { user: { name: 'Updated Name' } }
      expect(admin.reload.name).to eq('Updated Name')
    end
  end

  describe 'POST /admin/users/destroy/:id' do
    before { login_as_admin }

    let!(:other_user) { create(:user) }

    it 'deletes user' do
      expect {
        post "/admin/users/destroy/#{other_user.id}"
      }.to change(User, :count).by(-1)
    end
  end
end
