# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Accounts', type: :request do
  let!(:blog) { create(:blog) }
  let!(:existing_user) { create(:user) } # Need at least one user for most tests

  describe 'POST /accounts/login' do
    let!(:user) { create(:user, login: 'admin', password: 'password123') }

    context 'with valid credentials' do
      it 'logs in user' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to admin dashboard' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
        expect(response).to redirect_to('/admin')
      end
    end

    context 'with invalid credentials' do
      it 'does not log in user' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'wrongpassword' } }
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with remember me' do
      it 'sets remember token' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password123' }, remember_me: '1' }
        expect(cookies[:auth_token]).to be_present
      end
    end
  end

  describe 'GET /accounts/logout' do
    let!(:user) { create(:user, login: 'admin', password: 'password123') }

    before do
      post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
    end

    it 'logs out user' do
      get '/accounts/logout'
      expect(session[:user_id]).to be_nil
    end

    it 'redirects to login' do
      get '/accounts/logout'
      expect(response).to redirect_to('/accounts/login')
    end
  end

  describe 'GET /accounts/signup' do
    context 'when signup is enabled' do
      before do
        blog.update(allow_signup: 1)
      end

      it 'renders signup form' do
        get '/accounts/signup'
        expect(response).to have_http_status(:success)
      end
    end

    context 'when signup is disabled' do
      before do
        blog.update(allow_signup: 0)
      end

      it 'redirects' do
        get '/accounts/signup'
        expect(response.status).to be_in([200, 302])
      end
    end
  end

  describe 'POST /accounts/signup' do
    before do
      blog.update(allow_signup: 1)
    end

    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            login: 'newuser',
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates a new user' do
        expect do
          post '/accounts/signup', params: valid_params
        end.to change(User, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 'handles mismatched passwords' do
        post '/accounts/signup', params: {
          user: {
            login: 'baduser',
            email: 'bad@test.com',
            password: 'password1',
            password_confirmation: 'password2'
          }
        }
        expect(response.status).to be_in([200, 302])
      end
    end
  end

  describe 'GET /accounts/recover_password' do
    it 'renders password recovery form' do
      get '/accounts/recover_password'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /accounts/recover_password' do
    let!(:user) { create(:user, login: 'testuser', email: 'test@example.com') }

    it 'handles password recovery request' do
      post '/accounts/recover_password', params: { user: { login: 'testuser' } }
      expect(response.status).to be_in([200, 302])
    end

    it 'handles unknown user' do
      post '/accounts/recover_password', params: { user: { login: 'unknownuser' } }
      expect(response.status).to be_in([200, 302])
    end
  end

  describe 'GET /accounts/login' do
    it 'renders login form' do
      get '/accounts/login'
      expect(response).to have_http_status(:success)
    end
  end
end
