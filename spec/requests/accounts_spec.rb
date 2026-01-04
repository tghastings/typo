# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Accounts', type: :request do
  before(:each) do
    @blog = FactoryBot.create(:blog)
  end

  describe 'GET /accounts/login' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'redirects to signup' do
        get '/accounts/login'
        expect(response).to redirect_to('/accounts/signup')
      end
    end

    context 'when users exist' do
      before do
        @user = FactoryBot.create(:user, login: 'testuser', password: 'secretpass')
      end

      it 'renders the login page' do
        get '/accounts/login'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('login')
      end
    end

    context 'when already logged in' do
      before do
        @user = FactoryBot.create(:user, login: 'testuser', password: 'secretpass')
        post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' } }
      end

      it 'redirects to admin area' do
        get '/accounts/login'
        expect(response).to redirect_to('/admin')
      end
    end
  end

  describe 'POST /accounts/login' do
    before do
      @user = FactoryBot.create(:user, login: 'testuser', password: 'secretpass')
    end

    context 'with valid credentials' do
      it 'logs in successfully and redirects to admin area' do
        post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' } }
        expect(response).to redirect_to('/admin')
      end

      it 'sets session user_id' do
        post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' } }
        expect(session[:user_id]).to eq(@user.id)
      end

      it 'displays success flash message' do
        post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' } }
        expect(flash[:notice]).to include('Login successful')
      end
    end

    context 'with remember me checked' do
      it 'sets remember_token cookie' do
        post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' }, remember_me: '1' }
        expect(response).to redirect_to('/admin')
        expect(cookies[:auth_token]).not_to be_nil
      end
    end

    context 'with invalid credentials' do
      it 'does not log in with wrong password' do
        post '/accounts/login', params: { user: { login: 'testuser', password: 'wrongpassword' } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Login unsuccessful')
      end

      it 'does not log in with wrong username' do
        post '/accounts/login', params: { user: { login: 'wronguser', password: 'secretpass' } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Login unsuccessful')
      end

      it 'does not set session user_id' do
        post '/accounts/login', params: { user: { login: 'testuser', password: 'wrongpassword' } }
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with inactive user' do
      before do
        @inactive_user = FactoryBot.create(:user, login: 'inactiveuser', password: 'secretpass', state: 'inactive')
      end

      it 'does not log in inactive user' do
        post '/accounts/login', params: { user: { login: 'inactiveuser', password: 'secretpass' } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Login unsuccessful')
      end
    end
  end

  describe 'GET /accounts/logout' do
    before do
      @user = FactoryBot.create(:user, login: 'testuser', password: 'secretpass')
      post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' } }
    end

    it 'logs out and redirects to login' do
      get '/accounts/logout'
      expect(response).to redirect_to('/accounts/login')
    end

    it 'clears session user_id' do
      get '/accounts/logout'
      expect(session[:user_id]).to be_nil
    end

    it 'displays logout flash message' do
      get '/accounts/logout'
      expect(flash[:notice]).to include('Successfully logged out')
    end

    it 'clears auth_token cookie' do
      # First login with remember me
      get '/accounts/logout'
      post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' }, remember_me: '1' }
      get '/accounts/logout'
      expect(cookies[:auth_token]).to be_blank
    end
  end

  describe 'GET /accounts/signup' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'renders signup page' do
        get '/accounts/signup'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('signup')
      end
    end

    context 'when users exist and signup is disabled' do
      before do
        @user = FactoryBot.create(:user)
        @blog.update(allow_signup: 0)
      end

      it 'redirects to login' do
        get '/accounts/signup'
        expect(response).to redirect_to('/accounts/login')
      end
    end

    context 'when users exist and signup is enabled' do
      before do
        @user = FactoryBot.create(:user)
        Blog.first.update(allow_signup: 1)
      end

      it 'renders signup page' do
        get '/accounts/signup'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /accounts/signup' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'creates a new user with valid data' do
        expect do
          post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@example.com' } }
        end.to change(User, :count).by(1)
      end

      it 'redirects to confirm on success' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@example.com' } }
        expect(response).to redirect_to('/accounts/confirm')
      end

      it 'logs in the new user' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@example.com' } }
        expect(session[:user_id]).not_to be_nil
      end

      it 'sets temporary password in session' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@example.com' } }
        expect(session[:tmppass]).not_to be_nil
      end
    end

    context 'when signup is enabled and users exist' do
      before do
        @user = FactoryBot.create(:user)
        Blog.first.update(allow_signup: 1)
      end

      it 'creates a new user with valid data' do
        expect do
          post '/accounts/signup', params: { user: { login: 'newuser2', email: 'newuser2@example.com' } }
        end.to change(User, :count).by(1)
      end
    end

    context 'with invalid data' do
      before do
        User.delete_all
      end

      it 'does not create user with short login' do
        expect do
          post '/accounts/signup', params: { user: { login: 'ab', email: 'newuser@example.com' } }
        end.not_to change(User, :count)
      end

      it 'does not create user with missing email' do
        expect do
          post '/accounts/signup', params: { user: { login: 'newuser', email: '' } }
        end.not_to change(User, :count)
      end
    end
  end

  describe 'GET /accounts/recover_password' do
    before do
      @user = FactoryBot.create(:user, login: 'testuser', email: 'test@example.com')
    end

    it 'renders the password recovery page' do
      get '/accounts/recover_password'
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Recover')
    end
  end

  describe 'POST /accounts/recover_password' do
    before do
      @user = FactoryBot.create(:user, login: 'testuser', email: 'test@example.com', password: 'oldpassword')
      @old_password = @user.password
    end

    context 'with valid login' do
      it 'generates a new password and redirects to login' do
        post '/accounts/recover_password', params: { user: { login: 'testuser' } }
        expect(response).to redirect_to('/accounts/login')
      end

      it 'changes the user password' do
        post '/accounts/recover_password', params: { user: { login: 'testuser' } }
        @user.reload
        expect(@user.password).not_to eq(@old_password)
      end

      it 'displays success flash message' do
        post '/accounts/recover_password', params: { user: { login: 'testuser' } }
        expect(flash[:notice]).to include('email has been successfully sent')
      end
    end

    context 'with valid email' do
      it 'generates a new password and redirects to login' do
        post '/accounts/recover_password', params: { user: { login: 'test@example.com' } }
        expect(response).to redirect_to('/accounts/login')
      end
    end

    context 'with invalid login/email' do
      it 'displays error message' do
        post '/accounts/recover_password', params: { user: { login: 'nonexistent' } }
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to include('something wrong')
      end
    end
  end

  describe 'GET /accounts/index' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'redirects to signup' do
        get '/accounts/index'
        expect(response).to redirect_to('/accounts/signup')
      end
    end

    context 'when users exist' do
      before do
        @user = FactoryBot.create(:user)
      end

      it 'redirects to login' do
        get '/accounts/index'
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end

  describe 'cookie-based login' do
    before do
      @user = FactoryBot.create(:user, login: 'testuser', password: 'secretpass')
    end

    it 'sets remember token on user when remember me is checked' do
      post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' }, remember_me: '1' }
      @user.reload
      expect(@user.remember_token).not_to be_nil
      expect(@user.remember_token_expires_at).not_to be_nil
    end

    it 'sets auth_token cookie when remember me is checked' do
      post '/accounts/login', params: { user: { login: 'testuser', password: 'secretpass' }, remember_me: '1' }
      expect(cookies[:auth_token]).not_to be_nil
    end
  end
end
