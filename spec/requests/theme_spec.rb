# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Theme', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /stylesheets/theme/:filename' do
    it 'returns stylesheet or not found' do
      get '/stylesheets/theme/style.css'
      expect(response.status).to be_in([200, 404])
    end

    it 'blocks directory traversal' do
      get '/stylesheets/theme/../../../etc/passwd'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /javascripts/theme/:filename' do
    it 'returns javascript or not found' do
      get '/javascripts/theme/app.js'
      expect(response.status).to be_in([200, 404])
    end

    it 'blocks directory traversal' do
      get '/javascripts/theme/../../../etc/passwd'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /images/theme/:filename' do
    it 'returns image or not found' do
      get '/images/theme/logo.png'
      expect(response.status).to be_in([200, 404])
    end

    it 'blocks directory traversal' do
      get '/images/theme/../../../etc/passwd'
      expect(response).to have_http_status(:not_found)
    end
  end
end
