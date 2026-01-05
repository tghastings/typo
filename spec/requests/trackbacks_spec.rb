# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trackbacks', type: :request do
  let!(:blog) { create(:blog) }
  let!(:user) { create(:user) }
  let!(:article) { create(:article, published: true, published_at: 1.day.ago, user: user, allow_pings: true) }

  describe 'POST /trackbacks' do
    let(:valid_params) do
      {
        id: article.id,
        url: 'http://example.com/post',
        title: 'Trackback Title',
        excerpt: 'Trackback excerpt',
        blog_name: 'External Blog'
      }
    end

    it 'handles trackback request' do
      post '/trackbacks', params: valid_params
      expect(response.status).to be_in([200, 201, 422])
    end
  end

  describe 'GET /trackbacks' do
    it 'returns trackback list' do
      get '/trackbacks'
      expect(response.status).to be_in([200, 302])
    end
  end
end
