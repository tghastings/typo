# frozen_string_literal: true

require 'spec_helper'

describe AccountsController do
  describe "A successful login with 'Remember me' checked" do
    it 'should not cause password to change' do
      Factory(:blog)
      User.stub!(:salt).and_return('change-me')
      henri = Factory(:user, login: 'henri', password: 'testagain')
      post 'login', { user: { login: 'henri', password: 'testagain' }, remember_me: '1' }
      expect(request.session[:user_id]).to eq(henri.id)
    end
  end

  describe 'A successfully authenticated login' do
    before(:each) do
      Factory(:blog)
      User.stub!(:salt).and_return('change-me')
      @henri = Factory(:user, login: 'henri', password: 'testagain',
                              profile: Factory(:profile_admin, label: 'admin_henri'))
    end

    def make_request
      post 'login', { user: { login: 'henri', password: 'testagain' } }
    end

    it 'session gets a user' do
      make_request
      expect(request.session[:user_id]).to eq(@henri.id)
    end

    it 'sets typo_user_profile cookie' do
      make_request
      expect(cookies['typo_user_profile']).to eq('admin_henri')
    end

    it 'redirects to /bogus/location' do
      request.session[:return_to] = '/bogus/location'
      make_request
      expect(response).to redirect_to('/bogus/location')
    end

    it 'redirects to /admin if no return' do
      make_request
      expect(response).to redirect_to(controller: 'admin/dashboard')
    end

    it 'redirects to /admin if no return and you are logged in' do
      session[:user_id] = @henri.id
      make_request
      expect(response).to redirect_to(controller: 'admin/dashboard')
    end

    it 'should redirect to signup if no users' do
      User.stub!(:count).and_return(0)
      make_request
      expect(response).to redirect_to('/accounts/signup')
    end
  end

  describe 'User is inactive' do
    before(:each) do
      Factory(:blog)
      User.stub!(:authenticate).and_return(nil)
      User.stub!(:count).and_return(1)
    end

    def make_request
      post 'login', { user: { login: 'inactive', password: 'longtest' } }
    end

    it 'no user id goes in the session' do
      make_request
      expect(request.session[:user_id]).to be_nil
    end

    it 'login should == "inactive"' do
      make_request
      expect(assigns[:login]).to eq('inactive')
    end

    it 'typo_user_profile cookie should be blank' do
      make_request
      expect(cookies['typo_user_profile']).to be_blank
    end

    it 'should render login action' do
      make_request
      expect(response).to render_template(:login)
    end
  end

  describe 'Login with nil user and password' do
    before(:each) do
      Factory(:blog)
      User.stub!(:count).and_return(1)
    end

    def make_request
      post 'login', { user: { login: nil, password: nil } }
    end

    it 'should render login action' do
      make_request
      expect(response).to render_template(:login)
    end
  end

  describe 'Login gets the wrong password' do
    before(:each) do
      Factory(:blog)
      User.stub!(:authenticate).and_return(nil)
      User.stub!(:count).and_return(1)
    end

    def make_request
      post 'login', { user: { login: 'bob', password: 'test' } }
    end

    it 'no user in goes in the session' do
      make_request
      expect(request.session[:user_id]).to be_nil
    end

    it 'login should == "bob"' do
      make_request
      expect(assigns[:login]).to eq('bob')
    end

    it 'typo_user_profile cookie should be blank' do
      make_request
      expect(cookies['typo_user_profile']).to be_blank
    end

    it 'should render login action' do
      make_request
      expect(response).to render_template(:login)
    end
  end

  describe 'GET /index' do
    it 'should redirect to login' do
      Factory(:blog)
      User.stub!(:count).and_return(1)
      get 'index'
      expect(response).to redirect_to(action: 'login')
    end

    it 'should redirect to signup' do
      Factory(:blog)
      User.stub!(:count).and_return(0)
      get 'index'
      expect(response).to redirect_to(action: 'signup')
    end
  end

  describe 'GET /login' do
    it 'should render action :login' do
      Factory(:blog)
      User.stub!(:count).and_return(1)
      get 'login'
      expect(response).to render_template(:login)
      expect(assigns[:login]).to be_nil
    end
  end

  describe 'GET /login with 0 existing users' do
    before(:each) do
      Factory(:blog)
      User.stub!(:count).and_return(0)
    end

    it 'should render action :signup' do
      get 'login'
      expect(response).to redirect_to(action: 'signup')
      expect(assigns[:login]).to be_nil
    end

    it 'should render :signup' do
      get 'recover_password'
      expect(response).to redirect_to(action: 'signup')
    end
  end

  describe 'with >0 existing user and allow_signup = 0' do
    before(:each) do
      @blog = Factory(:blog)
      User.stub!(:count).and_return(1)
    end

    describe 'GET signup' do
      it 'should redirect to login' do
        get 'signup'
        expect(response).to redirect_to(action: 'login')
      end
    end

    describe 'POST signup without allow_signup' do
      it 'should redirect to login' do
        post 'signup', { 'user' => { 'login' => 'newbob' } }
        expect(response).to redirect_to(action: 'login')
      end
    end
  end

  describe 'with > 0 existing user and allow_signup = 1' do
    before(:each) do
      @blog = Factory(:blog, allow_signup: 1)
      User.stub!(:count).and_return(1)
    end

    describe 'GET signup with allow_signup' do
      it 'should redirect to login' do
        get 'signup'
        expect(response).to render_template('signup')
      end
    end

    describe 'POST signup with allow_signup' do
      it 'should redirect to login' do
        post 'signup', { 'user' => { 'login' => 'newbob', 'email' => 'newbob@mail.com' } }
        expect(response).to redirect_to(action: 'confirm')
      end
    end
  end
  describe 'GET signup with 0 existing users' do
    before(:each) do
      Factory(:blog)
      User.stub!(:count).and_return(0)
      @user = mock('user',
                   login: '',
                   email: '',
                   password: '',
                   password_confirmation: '',
                   name: '',
                   id: nil)
      @user.stub!(:reload).and_return(@user)
      User.stub!(:new).and_return(@user)
    end

    it 'sets @user' do
      get 'signup'
      expect(assigns[:user]).to eq(@user)
    end

    it 'renders action signup' do
      get 'signup'
      expect(response).to render_template(:signup)
    end
  end

  describe 'with 0 existing users and unconfigured blog' do
    before(:each) do
      Blog.delete_all
      @blog = Blog.new.save
      User.delete_all
    end

    describe 'when GET signup' do
      before { get 'signup' }
      it 'redirects to setup' do
        expect(response).to redirect_to(controller: 'setup', action: 'index')
      end
    end

    describe 'when POST signup' do
      before do
        post 'signup', { 'user' => { 'login' => 'newbob', 'password' => 'newpassword',
                                     'password_confirmation' => 'newpassword' } }
      end
      it 'redirects to setup' do
        expect(response).to redirect_to(controller: 'setup', action: 'index')
      end
    end

    describe 'when GET login' do
      before { get 'login' }
      it 'redirects to setup' do
        expect(response).to redirect_to(controller: 'setup', action: 'index')
      end
    end

    describe 'when POST login' do
      before do
        post 'login', { 'user' => { 'login' => 'newbob', 'password' => 'newpassword' } }
      end
      it 'redirects to setup' do
        expect(response).to redirect_to(controller: 'setup', action: 'index')
      end
    end
  end

  describe 'POST signup with 0 existing users' do
    before(:each) do
      Factory(:blog)
      User.stub!(:count).and_return(0)
      @user = mock_model(User)
      @user.stub!(:login).and_return('newbob')
      @user.stub!(:password=).and_return(true)
      @user.stub!(:password).and_return('foo')
      @user.stub!(:name=).and_return(true)
      User.stub!(:new).and_return(@user)
      User.stub!(:authenticate).and_return(@user)
      @user.stub!(:save).and_return(@user)
    end

    it 'creates and saves a user' do
      expect(User).to receive(:new).and_return(@user)
      expect(@user).to receive(:save).and_return(@user)
      post 'signup', params
      expect(assigns[:user]).to eq(@user)
    end

    it 'redirects to /account/confirm' do
      post 'signup', params
      expect(response).to redirect_to(action: 'confirm')
    end

    it 'session gets a user' do
      post 'signup', params
      expect(request.session[:user_id]).to eq(@user.id)
    end

    def params
      { 'user' => { 'login' => 'newbob', 'password' => 'newpassword',
                    'password_confirmation' => 'newpassword' } }
    end
  end

  describe 'User is logged in' do
    before(:each) do
      Factory(:blog)
      @user = Factory(:user)

      # The AccountsController class uses session[:user_id], and the
      # Typo LoginSystem uses session[:user].  So we need to set both of
      # these up correctly.  I'm not sure why the duplication exists.
      session[:user_id] = @user.id
      session[:user] = @user.id

      cookies['typo_user_profile'] = 'admin'
    end

    it 'trying to log in once again redirects to admin/dashboard/index' do
      get 'login'
      expect(response).to redirect_to(controller: 'admin/dashboard')
    end

    describe 'when logging out' do
      before do
        get 'logout'
      end

      it 'deletes the session[:user_id]' do
        expect(session[:user_id]).to be_blank
      end

      it 'session[:user_id] should be cleared after logout' do
        # After logout, session[:user_id] should be blank (covered by earlier test)
        expect(session[:user_id]).to be_blank
      end

      it 'redirects to the login action' do
        expect(response).to redirect_to(action: 'login')
      end

      it 'deletes cookies containing credentials' do
        expect(cookies['auth_token']).to eq(nil)
        expect(cookies['typo_user_profile']).to eq(nil)
      end
    end
  end

  describe 'when user has lost their password' do
    before(:each) do
      Factory(:blog)
      @user = Factory(:user)
      @user.profile = Profile.find_by_label('admin')
    end

    describe 'when GET' do
      before { get 'recover_password' }

      specify { expect(response).to render_template('recover_password') }
    end

    describe 'when a known login or email is POSTed' do
      before do
        post 'recover_password', { user: { login: @user.login } }
      end
      specify { expect(response).to redirect_to(action: 'login') }
    end

    describe 'when an unknown login or email is POSTed' do
      before do
        post 'recover_password', { user: { login: 'foobar' } }
      end

      specify { expect(response).to render_template('recover_password') }
      it 'should display an error' do
        expect(request.flash[:error]).not_to be_empty
      end
    end
  end
end
