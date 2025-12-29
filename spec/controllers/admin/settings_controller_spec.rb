require 'spec_helper'

describe Admin::SettingsController do
  render_views

  before(:each) do
    Factory(:blog)
    #TODO Remove this line after remove FIXTURE
    Profile.delete_all
    alice = Factory(:user, :login => 'alice', :profile => Factory(:profile_admin, :label => Profile::ADMIN))
    request.session = { :user_id => alice.id }
  end

  describe "#index" do
    before(:each) do
      get :index
    end
    
    it 'should render index' do  
      expect(response).to render_template('index')
    end
  end

  describe 'write action' do
    before(:each) do
      get :write
    end
    
    it 'should be success' do
      expect(response).to render_template('write')
    end    
  end

  describe 'feedback action' do
    before(:each) do
      get :feedback
    end
    
    it 'should be sucess' do
      expect(response).to render_template('feedback')
    end    
  end

  describe 'redirect action' do
    it 'should be success' do
      get :redirect
      expect(response).to be_redirect, :controller => 'admin/settings', :action => 'index'
    end
  end

  describe 'update action' do

    def good_update(options={})
      post :update, {"from"=>"seo",
        "authenticity_token"=>"f9ed457901b96c65e99ecb73991b694bd6e7c56b",
        "setting"=>{"permalink_format"=>"/%title%.html",
          "unindex_categories"=>"1",
          "google_analytics"=>"",
          "meta_keywords"=>"my keywords",
          "meta_description"=>"",
          "rss_description"=>"1",
          "robots"=>"User-agent: *\r\nDisallow: /admin/\r\nDisallow: /page/\r\nDisallow: /cgi-bin \r\nUser-agent: Googlebot-Image\r\nAllow: /*",
          "index_tags"=>"1"}}.merge(options)
    end

    it 'should success' do
      good_update
      expect(response).to redirect_to(:action => 'seo')
    end

    it 'should not save blog with bad permalink format' do
      @blog = Blog.default
      good_update "setting" => {"permalink_format" => "/%month%"}
      expect(response).to redirect_to(:action => 'seo')
      expect(@blog).to eq(Blog.default)
    end
  end
end
