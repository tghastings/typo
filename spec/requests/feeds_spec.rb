# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Feeds', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /comments.atom' do
    before do
      article = create(:article, published: true, published_at: 1.day.ago)
      create(:comment, article: article, state: 'ham')
    end

    it 'returns success' do
      get '/comments.atom'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /tag/:name.atom' do
    before do
      tag = create(:tag, name: 'ruby')
      article = create(:article, published: true, published_at: 1.day.ago)
      article.tags << tag
    end

    it 'returns success' do
      get '/tag/ruby.atom'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /category/:name.atom' do
    before do
      category = create(:category, name: 'Tech', permalink: 'tech')
      article = create(:article, published: true, published_at: 1.day.ago)
      article.categories << category
    end

    it 'returns success' do
      get '/category/tech.atom'
      expect(response).to have_http_status(:success)
    end
  end
end
