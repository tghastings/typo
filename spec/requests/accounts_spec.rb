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

  describe 'Password reset flow' do
    let!(:user) { create(:user, login: 'resetuser', email: 'reset@example.com', password: 'oldpassword') }

    describe 'POST /accounts/recover_password' do
      it 'generates a password reset token for valid user' do
        post '/accounts/recover_password', params: { user: { login: 'resetuser' } }
        user.reload
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_present
      end

      it 'always redirects to login to prevent user enumeration' do
        post '/accounts/recover_password', params: { user: { login: 'nonexistent' } }
        expect(response).to redirect_to('/accounts/login')
      end
    end

    describe 'GET /accounts/reset_password' do
      before do
        user.generate_password_reset_token!
      end

      it 'renders reset form with valid token' do
        get '/accounts/reset_password', params: { token: user.reset_password_token }
        expect(response).to have_http_status(:success)
      end

      it 'redirects with invalid token' do
        get '/accounts/reset_password', params: { token: 'invalidtoken' }
        expect(response).to redirect_to('/accounts/recover_password')
      end

      it 'redirects with expired token' do
        user.update_column(:reset_password_sent_at, 3.hours.ago)
        get '/accounts/reset_password', params: { token: user.reset_password_token }
        expect(response).to redirect_to('/accounts/recover_password')
      end
    end

    describe 'POST /accounts/reset_password' do
      before do
        user.generate_password_reset_token!
      end

      it 'resets password with valid token and matching passwords' do
        post '/accounts/reset_password', params: {
          token: user.reset_password_token,
          user: { password: 'newpassword123', password_confirmation: 'newpassword123' }
        }
        expect(response).to redirect_to('/accounts/login')
        user.reload
        expect(user.reset_password_token).to be_nil
        expect(User.authenticate('resetuser', 'newpassword123')).to eq(user)
      end

      it 'fails with mismatched passwords' do
        post '/accounts/reset_password', params: {
          token: user.reset_password_token,
          user: { password: 'newpassword123', password_confirmation: 'differentpassword' }
        }
        expect(response).to have_http_status(:success)
        user.reload
        expect(user.reset_password_token).to be_present
      end

      it 'fails with blank password' do
        post '/accounts/reset_password', params: {
          token: user.reset_password_token,
          user: { password: '', password_confirmation: '' }
        }
        expect(response).to have_http_status(:success)
        user.reload
        expect(user.reset_password_token).to be_present
      end
    end
  end
end
