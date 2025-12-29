require 'spec_helper'

describe Admin::SidebarController do
  before do
    Factory(:blog)
    #TODO Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, :login => 'henri', :profile => Factory(:profile_admin, :label => Profile::ADMIN))
    request.session = { :user_id => henri.id }
  end

  describe "rendering" do
    render_views

    it "test_index" do
      get :index
      expect(response).to render_template('index')
      expect(response.body).to have_selector("div#sidebar-config")
    end
  end
end
