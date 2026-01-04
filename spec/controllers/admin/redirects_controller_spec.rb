# frozen_string_literal: true

require 'spec_helper'

describe Admin::RedirectsController do
  render_views

  before do
    Factory(:blog)
    # TODO: Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: henri.id }
  end

  describe '#index' do
    before(:each) do
      get :index
    end

    it 'should display index with redirects' do
      expect(response).to redirect_to(action: 'new')
    end
  end

  it 'test_create' do
    expect do
      post :edit, 'redirect' => { from_path: 'some/place',
                                  to_path: 'somewhere/else' }
      expect(response).to redirect_to(action: 'index')
    end.to change(Redirect, :count)
  end

  it 'test_create with empty from path' do
    expect do
      post :edit, 'redirect' => { from_path: '',
                                  to_path: 'somewhere/else/else' }
      expect(response).to redirect_to(action: 'index')
    end.to change(Redirect, :count)
  end

  describe '#edit' do
    before(:each) do
      get :edit, id: Factory(:redirect).id
    end

    it 'should render new template with valid redirect' do
      expect(response).to render_template('new')
      expect(assigns(:redirect)).not_to be_nil
      expect(assigns(:redirect)).to be_valid
    end
  end

  it 'test_update' do
    post :edit, id: Factory(:redirect).id
    expect(response).to redirect_to(action: 'index')
  end

  describe 'test_destroy' do
    before(:each) do
      @test_id = Factory(:redirect).id
      expect(Redirect.find(@test_id)).not_to be_nil
    end

    describe 'with GET' do
      before(:each) do
        get :destroy, id: @test_id
      end

      it 'should render destroy template' do
        expect(response).to be_successful
        expect(response).to render_template('destroy')
      end
    end

    describe 'with POST' do
      before(:each) do
        post :destroy, id: @test_id
      end

      it 'should redirect to index' do
        expect(response).to redirect_to(action: 'index')
      end

      it 'should have no more redirects' do
        expect { Redirect.find(@test_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
