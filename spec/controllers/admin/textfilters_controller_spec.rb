# frozen_string_literal: true

require 'spec_helper'

describe Admin::TextfiltersController do
  render_views

  describe 'macro help action' do
    it 'should render success' do
      Factory(:blog)
      # TODO: Delete after removing fixtures
      Profile.delete_all
      henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
      request.session = { user_id: henri.id }
      get 'macro_help', id: 'code'
      expect(response).to be_success
    end
  end
end
