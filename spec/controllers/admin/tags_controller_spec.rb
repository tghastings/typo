# frozen_string_literal: true

require 'spec_helper'

describe Admin::TagsController do
  render_views

  before do
    Factory(:blog)
    # TODO: Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: henri.id }
  end

  describe 'index action' do
    before :each do
      get :index
    end

    it 'should be success' do
      expect(response).to be_success
    end

    it 'should render template index' do
      expect(response).to render_template('index')
    end
  end

  describe 'edit action' do
    before(:each) do
      tag_id = Factory(:tag).id
      get :edit, id: tag_id
    end

    it 'should be success' do
      expect(response).to be_success
    end

    it 'should render template edit' do
      expect(response).to render_template('edit')
    end

    it 'should assigns value :tag' do
      expect(assigns(:tag)).to be_valid
    end
  end

  describe 'destroy action with GET' do
    before(:each) do
      @tag_id = Factory(:tag).id
      get :destroy, id: @tag_id
    end

    it 'should be success' do
      expect(response).to be_success
    end

    it 'should have an id in the form destination' do
      expect(response).to have_selector("form[action='/admin/tags/destroy/#{@tag_id}'][method='post']")
    end

    it 'should render template edit' do
      expect(response).to render_template('destroy')
    end

    it 'should assigns value :tag' do
      expect(assigns(:record)).to be_valid
    end
  end

  describe 'destroy action with POST' do
    before do
      @tag = Factory(:tag)
      post :destroy, 'id' => @tag.id, 'tag' => { display_name: 'Foo Bar' }
    end

    it 'should redirect to index' do
      expect(response).to redirect_to(action: 'index')
    end

    it 'should have one less tags' do
      expect(Tag.count).to eq(0)
    end
  end

  describe 'update action' do
    before do
      @tag = Factory(:tag)
      post :edit, 'id' => @tag.id, 'tag' => { display_name: 'Foo Bar' }
    end

    it 'should redirect to index' do
      expect(response).to redirect_to(action: 'index')
    end

    it 'should update tag' do
      @tag.reload
      expect(@tag.name).to eq('foo-bar')
      expect(@tag.display_name).to eq('Foo Bar')
    end

    it 'should create a redirect from the old to the new' do
      old_name = @tag.name
      @tag.reload
      new_name = @tag.name

      r = Redirect.find_by_from_path "/tag/#{old_name}"
      expect(r.to_path).to eq("/tag/#{new_name}")
    end
  end
end
