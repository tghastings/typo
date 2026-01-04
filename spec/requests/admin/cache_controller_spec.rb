# frozen_string_literal: true

require 'spec_helper'

describe Admin::CacheController, type: :request do
  let!(:blog) { FactoryBot.create(:blog) }

  def login_admin
    admin_profile = Profile.find_by(label: 'admin') || FactoryBot.create(:profile_admin)
    user = FactoryBot.create(:user, profile: admin_profile, password: 'password')
    post '/accounts/login', params: { user: { login: user.login, password: 'password' } }
    user
  end

  describe 'GET /admin/cache' do
    context 'when logged in as admin' do
      before { login_admin }

      it 'renders the index page' do
        get '/admin/cache'
        expect(response).to be_successful
      end

      it 'displays cache information' do
        get '/admin/cache'
        expect(response.body).to include('Cache')
      end
    end

    context 'when not logged in' do
      it 'redirects to login or signup' do
        get '/admin/cache'
        expect(response).to be_redirect
      end
    end
  end
end
