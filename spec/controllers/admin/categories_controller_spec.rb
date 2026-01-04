# frozen_string_literal: true

require 'spec_helper'

describe Admin::CategoriesController do
  render_views

  before(:each) do
    Factory(:blog)
    # TODO: Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: henri.id }
  end

  it 'test_index' do
    get :index
    expect(response).to redirect_to(action: 'new')
  end

  describe 'test_edit' do
    before(:each) do
      get :edit, id: Factory(:category).id
    end

    it 'should render template new' do
      expect(response).to render_template('new')
      expect(response.body).to have_selector('table#category_container')
    end

    it 'should have valid category' do
      expect(assigns(:category)).not_to be_nil
      expect(assigns(:category)).to be_valid
      expect(assigns(:categories)).not_to be_nil
    end
  end

  it 'test_update' do
    post :edit, id: Factory(:category).id
    expect(response).to redirect_to(action: 'new')
  end

  describe 'test_destroy with GET' do
    before(:each) do
      test_id = Factory(:category).id
      expect(Category.find(test_id)).not_to be_nil
      get :destroy, id: test_id
    end

    it 'should render destroy template' do
      expect(response).to be_successful
      expect(response).to render_template('destroy')
    end
  end

  it 'test_destroy with POST' do
    test_id = Factory(:category).id
    expect(Category.find(test_id)).not_to be_nil
    get :destroy, id: test_id

    post :destroy, id: test_id
    expect(response).to redirect_to(action: 'new')

    expect { Category.find(test_id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
