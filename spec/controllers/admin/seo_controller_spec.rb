# frozen_string_literal: true

require 'spec_helper'

describe Admin::SeoController do
  render_views

  before(:each) do
    Factory(:blog)
    # TODO: Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: henri.id }
  end

  describe '#index' do
    before do
      get :index
    end

    it 'should render index' do
      expect(response).to render_template('index')
    end
  end

  describe '#permalinks' do
    before do
      get :permalinks
    end

    it 'should render permalinks' do
      expect(response).to render_template('permalinks')
    end
  end

  describe '#titles' do
    before(:each) do
      get :titles
    end

    it 'should render titles' do
      expect(response).to render_template('titles')
    end
  end

  describe 'update action' do
    def good_update(options = {})
      post :update, { 'from' => 'permalinks',
                      'authenticity_token' => 'f9ed457901b96c65e99ecb73991b694bd6e7c56b',
                      'setting' => { 'permalink_format' => '/%title%' } }.merge(options)
    end

    it 'should success' do
      good_update
      expect(response).to redirect_to(action: 'permalinks')
    end

    it 'should not save blog with bad permalink format' do
      @blog = Blog.default
      good_update 'setting' => { 'permalink_format' => '/%month%' }
      expect(response).to redirect_to(action: 'permalinks')
      expect(@blog).to eq(Blog.default)
    end
  end
end
