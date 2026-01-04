# frozen_string_literal: true

require 'spec_helper'

describe Admin::CacheController do
  render_views

  before do
    Factory(:blog)
    # TODO: Delete after removing fixtures
    Profile.delete_all
    @henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: @henri.id }
  end

  describe 'test_index' do
    before(:each) do
      get :index
    end

    it 'should render template index' do
      expect(response).to render_template('index')
    end
  end
end
