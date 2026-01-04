# frozen_string_literal: true

require 'spec_helper'

describe ThemeController, type: :request do
  let!(:blog) { FactoryBot.create(:blog) }

  describe 'GET /stylesheets/theme/:filename' do
    it 'returns 404 for directory traversal attempt' do
      get '/stylesheets/theme/../../../etc/passwd'
      expect(response).to have_http_status(404)
    end

    it 'returns 404 for non-existent file' do
      get '/stylesheets/theme/nonexistent.css'
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /javascripts/theme/:filename' do
    it 'returns 404 for directory traversal attempt' do
      get '/javascripts/theme/../../../etc/passwd'
      expect(response).to have_http_status(404)
    end

    it 'returns 404 for non-existent file' do
      get '/javascripts/theme/nonexistent.js'
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /images/theme/:filename' do
    it 'returns 404 for directory traversal attempt' do
      get '/images/theme/../../../etc/passwd'
      expect(response).to have_http_status(404)
    end

    it 'returns 404 for non-existent file' do
      get '/images/theme/nonexistent.png'
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /theme/static_view_test' do
    it 'renders static view test' do
      get '/theme/static_view_test'
      expect(response).to be_successful
    end
  end
end
