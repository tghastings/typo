require 'spec_helper'

describe Admin::UsersController, "rough port of the old functional test" do
  render_views

  describe ' when you are admin' do
    before(:each) do
      Factory(:blog)
            @admin = Factory(:user, :profile => Factory(:profile_admin, :label => Profile::ADMIN))
      request.session = { :user_id => @admin.id }
    end

    it "test_index" do
      get :index
      expect(response).to render_template('index')
      expect(assigns(:users)).not_to be_nil
    end

    it "test_new" do
      get :new
      expect(response).to render_template('new')

      post :new, :user => { :login => 'errand', :email => 'corey@test.com',
        :password => 'testpass', :password_confirmation => 'testpass', :profile_id => 1, 
        :nickname => 'fooo', :firstname => 'bar' }
      expect(response).to redirect_to(:action => 'index')
    end

    describe '#EDIT action' do

      describe 'with POST request' do
        it 'should redirect to index' do
          post :edit, :id => @admin.id, :user => { :login => 'errand',
            :email => 'corey@test.com', :password => 'testpass',
            :password_confirmation => 'testpass' }
          expect(response).to redirect_to(:action => 'index')
        end
      end

      describe 'with GET request' do
        shared_examples_for 'edit admin render' do
          it 'should render template edit' do
            expect(response).to render_template('edit')
          end

          it 'should assigns tobi user' do
            expect(assigns(:user)).to be_valid
            expect(assigns(:user)).to eq(@admin )
          end
        end
        describe 'with no id params' do
          before do
            get :edit
          end
          it_should_behave_like 'edit admin render'
        end

        describe 'with id params' do
          before do
            get :edit, :id => @admin.id
          end
          it_should_behave_like 'edit admin render'
        end

      end
  end

    it "test_destroy" do
      user_count = User.count
      get :destroy, :id => @admin.id
      expect(response).to render_template('destroy')
      expect(assigns(:record)).to be_valid

      user = Factory.build(:user)
      expect(user).to receive(:destroy)
      expect(User).to receive(:count).and_return(2)
      expect(User).to receive(:find).with(@admin.id.to_s).and_return(user)
      post :destroy, :id => @admin.id
      expect(response).to redirect_to(:action => 'index')
    end
  end

  describe 'when you are not admin' do

    before :each do
      Factory(:blog)
      user = Factory(:user)
      session[:user] = user.id
    end

    it "don't see the list of user" do
      get :index
      expect(response).to redirect_to(:controller => "/accounts", :action => "login")
    end

    describe 'EDIT Action' do

      describe 'try update another user' do
        before do
          @admin_profile = Factory.create(:profile_admin)
          @administrator = Factory.create(:user, :profile => @admin_profile)
          contributor = Factory.create(:profile_contributor)
          post :edit,
            :id => @administrator.id,
            :profile_id => contributor.id
        end

        it 'should redirect to login' do
          expect(response).to redirect_to(:controller => "/accounts", :action => "login")
        end

        it 'should not change user profile' do
          u = @administrator.reload
          expect(u.profile_id).to eq(@admin_profile.id)
        end
      end
    end
  end
end
