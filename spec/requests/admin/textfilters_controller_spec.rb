# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Textfilters', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/textfilters/macro_help/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/textfilters/macro_help/code'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns help text for code macro' do
        get '/admin/textfilters/macro_help/code'
        expect(response).to be_successful
      end

      it 'returns help text for flickr macro' do
        get '/admin/textfilters/macro_help/flickr'
        expect(response).to be_successful
      end

      it 'returns help text for lightbox macro' do
        get '/admin/textfilters/macro_help/lightbox'
        expect(response).to be_successful
      end
    end
  end
end
