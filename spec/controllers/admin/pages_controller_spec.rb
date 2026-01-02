# coding: utf-8
require 'spec_helper'

describe Admin::PagesController do
  render_views
  
  before do
    @blog = Factory(:blog)
    #TODO Delete after removing fixtures
    Profile.delete_all
    @henri = Factory(:user, :login => 'henri', :profile => Factory(:profile_admin, :label => Profile::ADMIN))
    request.session = { :user_id => @henri.id }
  end

  describe '#index' do
    it 'should response success' do
      get :index
      expect(response).to be_success
      expect(response).to render_template('index')
      expect(assigns(:pages)).not_to be_nil
    end

    it 'should response success with :page args' do
      get :index, :page => 1
      expect(response).to be_success
      expect(response).to render_template('index')
      expect(assigns(:pages)).not_to be_nil
    end

  end

  describe "new" do
    
    context "without page params" do
      before(:each) do
        get :new
      end

      it "should render template new and has a page object" do
        expect(response).to be_successful
        expect(response).to render_template("new")
        expect(assigns(:page)).not_to be_nil
      end

      it "should assign to current user" do
        expect(assigns(:page).user).to eq(@henri)
      end

      it "should have a text filter" do
        expect(assigns(:page).text_filter).to eq(TextFilter.find_by_name(@blog.text_filter))
      end
    end

  end

  it "test_create" do
    post :new, :page => { :name => "new_page", :title => "New Page Title",
      :body => "Emphasis _mine_, arguments *strong*" }

    new_page = Page.order("id DESC").first

    expect(new_page.name).to eq("new_page")

    expect(response).to redirect_to(action: 'index')

    # XXX: The flash is currently being made available improperly to tests (scoop)
    expect(flash[:notice]).to eq("Page was successfully created.")
  end

  describe "test_edit" do
    before(:each) do
      @page = Factory(:page)
      get :edit, :id => @page.id
    end

    it 'should render edit template' do
      expect(response).to be_successful
      expect(response).to render_template("edit")
      expect(assigns(:page)).not_to be_nil
      expect(assigns(:page)).to eq(@page)
    end

  end

  it 'test_update' do
    page = Factory(:page)
    post :edit, :id => page.id, :page => { :name => "markdown-page", :title => "Markdown Page",
      :body => "Adding a [link](http://www.typosphere.org/) here" }

    expect(response).to redirect_to(action: 'index')

    # XXX: The flash is currently being made available improperly to tests (scoop)
    #expect(flash[:notice]).to eq("Page was successfully updated.")
  end

  it "test_destroy" do
    page = Factory(:page)
    post :destroy, :id => page.id
    expect(response).to redirect_to(action: 'index')
    expect { Page.find(page.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  def base_page(options={})
    { :title => "posted via tests!",
      :body => "A good body",
      :name => "posted-via-tests",
      :published => true }.merge(options)
  end

  it 'should create a published page with a redirect' do
    post(:new, 'page' => base_page)
    expect(assigns(:page).redirects.count).to eq(1)
  end

  it 'should create an unpublished page without a redirect' do
    post(:new, 'page' => base_page({:published => false}))
    expect(assigns(:page).redirects.count).to eq(0)
  end

  it 'should create a page published in the future without a redirect' do
    pending ":published_at parameter is currently ignored"
    post(:new, 'page' => base_page({:published_at => (Time.now + 1.hour).to_s}))
    expect(assigns(:page).redirects.count).to eq(0)
  end

  describe 'insert_editor action' do
    it 'should render _markdown_editor for any editor param' do
      get(:insert_editor, :editor => 'simple')
      expect(response).to render_template('admin/shared/_markdown_editor')
    end

    it 'should render _markdown_editor for visual param' do
      get(:insert_editor, :editor => 'visual')
      expect(response).to render_template('admin/shared/_markdown_editor')
    end

    it 'should render _markdown_editor even if editor param is set to unknown editor' do
      get(:insert_editor, :editor => 'unknown')
      expect(response).to render_template('admin/shared/_markdown_editor')
    end
  end
end
