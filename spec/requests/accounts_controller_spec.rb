# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Accounts', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /accounts/login' do
    context 'when not logged in' do
      it 'returns successful response' do
        get '/accounts/login'
        expect(response).to be_successful
      end

      it 'displays the login form' do
        get '/accounts/login'
        expect(response.body).to include('login')
      end

      it 'displays the blog name in the page title' do
        get '/accounts/login'
        expect(response.body).to include(@blog.blog_name)
      end
    end

    context 'when already logged in' do
      before { login_admin }

      it 'redirects to admin dashboard' do
        get '/accounts/login'
        expect(response).to redirect_to(controller: 'admin/dashboard', action: 'index')
      end
    end
  end

  describe 'POST /accounts/login' do
    context 'with valid credentials' do
      it 'logs in the user successfully' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' } }
        expect(response).to redirect_to(controller: 'admin/dashboard', action: 'index')
      end

      it 'sets the session user_id' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' } }
        expect(session[:user_id]).to eq(@admin.id)
      end

      it 'displays a success flash message' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' } }
        expect(flash[:notice]).to include('successful')
      end

      it 'updates the user connection time' do
        old_time = @admin.last_connection
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' } }
        @admin.reload
        expect(@admin.last_connection).not_to eq(old_time)
      end
    end

    context 'with remember me option' do
      it 'sets remember token cookie when remember_me is checked' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' }, remember_me: '1' }
        expect(cookies[:auth_token]).not_to be_nil
      end

      it 'does not set remember token cookie when remember_me is not checked' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' } }
        expect(cookies[:auth_token]).to be_nil
      end
    end

    context 'with invalid credentials' do
      it 'does not redirect' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'wrongpassword' } }
        expect(response).not_to be_redirect
      end

      it 'displays an error message' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'wrongpassword' } }
        expect(response.body).to include('unsuccessful')
      end

      it 'does not set session user_id' do
        post '/accounts/login', params: { user: { login: 'admin', password: 'wrongpassword' } }
        expect(session[:user_id]).to be_nil
      end

      it 'renders the login form again' do
        post '/accounts/login', params: { user: { login: 'testlogin', password: 'wrongpassword' } }
        # The login form is re-rendered for the user to try again
        expect(response.body).to include('Login')
        expect(response.body).to include('user[login]')
      end
    end

    context 'with non-existent user' do
      it 'displays an error message' do
        post '/accounts/login', params: { user: { login: 'nonexistent', password: 'password' } }
        expect(response.body).to include('unsuccessful')
      end

      it 'does not set session' do
        post '/accounts/login', params: { user: { login: 'nonexistent', password: 'password' } }
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe 'GET /accounts/logout' do
    context 'when logged in' do
      before { login_admin }

      it 'logs out the user' do
        get '/accounts/logout'
        expect(session[:user_id]).to be_nil
      end

      it 'redirects to login page' do
        get '/accounts/logout'
        expect(response).to redirect_to(action: 'login')
      end

      it 'displays a success flash message' do
        get '/accounts/logout'
        expect(flash[:notice]).to include('logged out')
      end

      it 'clears the auth_token cookie' do
        # First login with remember_me
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' }, remember_me: '1' }
        get '/accounts/logout'
        expect(cookies[:auth_token]).to be_nil
      end

      it 'clears the typo_user_profile cookie' do
        # First we need to login which sets the cookie
        post '/accounts/login', params: { user: { login: 'admin', password: 'password' } }
        expect(cookies[:typo_user_profile]).not_to be_nil
        # Now logout should clear it
        get '/accounts/logout'
        # After logout, the cookie value should be empty/deleted
        expect(cookies[:typo_user_profile]).to be_blank
      end
    end
  end

  describe 'GET /accounts/signup' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'returns successful response' do
        get '/accounts/signup'
        expect(response).to be_successful
      end

      it 'displays the signup form' do
        get '/accounts/signup'
        expect(response.body).to include('signup')
      end

      it 'displays the blog name in the page title' do
        get '/accounts/signup'
        expect(response.body).to include(@blog.blog_name)
      end
    end

    context 'when users exist and signup is disabled' do
      it 'redirects to login page' do
        get '/accounts/signup'
        expect(response).to redirect_to(action: 'login')
      end
    end

    context 'when users exist and signup is enabled' do
      before do
        @blog.allow_signup = 1
        @blog.save!
      end

      it 'returns successful response' do
        get '/accounts/signup'
        expect(response).to be_successful
      end

      it 'displays the signup form' do
        get '/accounts/signup'
        expect(response.body).to include('signup')
      end
    end
  end

  describe 'POST /accounts/signup' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'creates a new user with valid params' do
        expect {
          post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        }.to change { User.count }.by(1)
      end

      it 'redirects to confirm page on success' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        expect(response).to redirect_to(controller: 'accounts', action: 'confirm')
      end

      it 'logs in the new user' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        expect(session[:user_id]).not_to be_nil
      end

      it 'stores temporary password in session' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        expect(session[:tmppass]).not_to be_nil
      end

      it 'sets the user name to login' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        user = User.find_by(login: 'newuser')
        expect(user.name).to eq('newuser')
      end

      it 'does not create user with invalid params' do
        expect {
          post '/accounts/signup', params: { user: { login: '', email: '' } }
        }.not_to change { User.count }
      end

      it 'returns successful response with invalid params (re-renders form)' do
        post '/accounts/signup', params: { user: { login: '', email: '' } }
        expect(response).to be_successful
      end
    end

    context 'when users exist and signup is disabled' do
      it 'redirects to login page' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        expect(response).to redirect_to(action: 'login')
      end

      it 'does not create a new user' do
        expect {
          post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        }.not_to change { User.count }
      end
    end

    context 'when users exist and signup is enabled' do
      before do
        @blog.allow_signup = 1
        @blog.save!
      end

      it 'creates a new user with valid params' do
        expect {
          post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        }.to change { User.count }.by(1)
      end

      it 'redirects to confirm page on success' do
        post '/accounts/signup', params: { user: { login: 'newuser', email: 'newuser@test.com' } }
        expect(response).to redirect_to(controller: 'accounts', action: 'confirm')
      end
    end
  end

  describe 'GET /accounts/recover_password' do
    it 'returns successful response' do
      get '/accounts/recover_password'
      expect(response).to be_successful
    end

    it 'displays the recovery form' do
      get '/accounts/recover_password'
      expect(response.body).to include('password')
    end

    it 'displays the blog name in the page title' do
      get '/accounts/recover_password'
      expect(response.body).to include(@blog.blog_name)
    end
  end

  describe 'POST /accounts/recover_password' do
    context 'with valid login' do
      it 'resets the password' do
        old_password = @admin.password
        post '/accounts/recover_password', params: { user: { login: 'admin' } }
        @admin.reload
        expect(@admin.password).not_to eq(old_password)
      end

      it 'redirects to login page' do
        post '/accounts/recover_password', params: { user: { login: 'admin' } }
        expect(response).to redirect_to(action: 'login')
      end

      it 'displays a success flash message' do
        post '/accounts/recover_password', params: { user: { login: 'admin' } }
        expect(flash[:notice]).to include('email')
      end
    end

    context 'with valid email' do
      it 'resets the password' do
        old_password = @admin.password
        post '/accounts/recover_password', params: { user: { login: @admin.email } }
        @admin.reload
        expect(@admin.password).not_to eq(old_password)
      end

      it 'redirects to login page' do
        post '/accounts/recover_password', params: { user: { login: @admin.email } }
        expect(response).to redirect_to(action: 'login')
      end
    end

    context 'with invalid login/email' do
      it 'does not redirect' do
        post '/accounts/recover_password', params: { user: { login: 'nonexistent' } }
        expect(response).not_to be_redirect
      end

      it 'displays an error message' do
        post '/accounts/recover_password', params: { user: { login: 'nonexistent' } }
        expect(flash[:error]).to include('wrong')
      end
    end
  end

  describe 'GET /accounts/confirm' do
    context 'when logged in with tmppass in session' do
      before do
        login_admin
      end

      it 'returns successful response' do
        get '/accounts/confirm'
        expect(response).to be_successful
      end

      it 'displays the confirmation page' do
        get '/accounts/confirm'
        expect(response.body).to include('Congratulations')
      end
    end
  end

  describe 'GET /accounts (index)' do
    context 'when no users exist' do
      before do
        User.delete_all
      end

      it 'redirects to signup' do
        get '/accounts/index'
        expect(response).to redirect_to(action: 'signup')
      end
    end

    context 'when users exist' do
      it 'redirects to login' do
        get '/accounts/index'
        expect(response).to redirect_to(action: 'login')
      end
    end
  end

  describe 'redirect when no users exist' do
    before do
      User.delete_all
    end

    it 'redirects login to signup when no users' do
      get '/accounts/login'
      expect(response).to redirect_to(controller: 'accounts', action: 'signup')
    end

    it 'redirects recover_password to signup when no users' do
      get '/accounts/recover_password'
      expect(response).to redirect_to(controller: 'accounts', action: 'signup')
    end
  end

  describe 'blog not configured' do
    before do
      # Remove blog_name from settings to make it unconfigured
      @blog.settings.delete('blog_name')
      @blog.save(validate: false)
    end

    it 'redirects to setup when blog is not configured' do
      get '/accounts/login'
      expect(response).to redirect_to(controller: 'setup', action: 'index')
    end
  end
end
