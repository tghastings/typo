require 'spec_helper'

describe Admin::ResourcesController do
  render_views

  before do
    Factory(:blog)
    #TODO Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, :login => 'henri', :profile => Factory(:profile_admin, :label => Profile::ADMIN))
    @request.session = { :user_id => henri.id }
  end

  describe "test_index" do
    before(:each) do
      get :index
    end
    
    it "should render index template" do
      expect(response).to be_successful
      expect(response).to render_template('index')
      expect(assigns(:resources)).not_to be_nil
    end    
  end

  describe "test_destroy_image with get" do
    before(:each) do
      @res_id = Factory(:resource).id
      get :destroy, :id => @res_id
    end
    
    it "should render template destroy" do
      expect(response).to be_successful
      expect(response).to render_template('destroy')
    end
    
    it 'should have a valid file' do
      expect(Resource.find(@res_id)).not_to be_nil
      expect(assigns(:record)      ).not_to be_nil
    end    
  end
    
  it 'test_destroy_image with POST' do
    res_id = Factory(:resource).id

    post :destroy, :id => res_id
    expect(response).to redirect_to(:action => 'index')
  end

  it "test_upload" do
    # unsure how to test upload constructs :'(
  end
end
