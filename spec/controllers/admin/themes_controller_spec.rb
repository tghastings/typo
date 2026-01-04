# frozen_string_literal: true

require 'spec_helper'

describe Admin::ThemesController do
  render_views

  before do
    Factory(:blog)
    # TODO: Delete after removing fixtures
    Profile.delete_all
    henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    request.session = { user_id: henri.id }
  end

  describe 'test index' do
    before(:each) do
      get :index
    end

    it 'assigns @themes for the :index action' do
      expect(response).to be_successful
      expect(assigns(:themes)).not_to be_nil
    end
  end

  it 'redirects to :index after the :switchto action' do
    get :switchto, theme: 'scribbish'
    expect(response).to redirect_to(action: 'index')
  end

  it 'returns succes for the :preview action' do
    get :preview, theme: 'scribbish'
    expect(response).to be_successful
  end
end
