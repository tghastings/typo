# frozen_string_literal: true

require 'spec_helper'

describe Admin::PostTypesController do
  render_views
  before do
    Factory(:blog)
    # TODO: delete this after remove fixture
    Profile.delete_all
    @user = Factory(:user, profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: @user.id }
  end

  it 'index shoudld redirect to new' do
    get :index
    expect(response).to redirect_to(action: 'new')
  end

  it 'test_create' do
    pt = Factory(:post_type)
    expect(PostType).to receive(:all).and_return([])
    expect(PostType).to receive(:new).and_return(pt)
    expect(pt).to receive(:save!).and_return(true)
    post :edit, 'post_type' => { name: 'new post type' }
    expect(response).to be_redirect
    expect(response).to redirect_to(action: 'index')
  end

  describe 'test_new' do
    before(:each) do
      get :new
    end

    it 'should render template new' do
      expect(response).to render_template('new')
    end
  end

  describe 'test_edit' do
    it 'should render template new' do
      get :edit, id: Factory(:post_type).id
      expect(response).to render_template('new')
    end

    it 'test_update' do
      post :edit, id: Factory(:post_type).id
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe 'test_destroy with GET' do
    before(:each) do
      test_id = Factory(:post_type).id
      expect(PostType.find(test_id)).not_to be_nil
      get :destroy, id: test_id
    end

    it 'should render destroy template' do
      expect(response).to be_successful
      expect(response).to render_template('destroy')
    end
  end

  it 'test_destroy with POST' do
    test_id = Factory(:post_type).id
    expect(PostType.find(test_id)).not_to be_nil
    get :destroy, id: test_id

    post :destroy, id: test_id
    expect(response).to redirect_to(action: 'index')

    expect { PostType.find(test_id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
