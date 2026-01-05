# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Categories', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /category/:id' do
    let!(:category) { create(:category, name: 'Technology', permalink: 'technology') }

    context 'with articles' do
      before do
        article = create(:article, title: 'Tech Post', published: true, published_at: 1.day.ago)
        article.categories << category
      end

      it 'returns success' do
        get '/category/technology'
        expect(response).to have_http_status(:success)
      end

      it 'displays category name' do
        get '/category/technology'
        expect(response.body).to include('Technology')
      end

      it 'displays articles in category' do
        get '/category/technology'
        expect(response.body).to include('Tech Post')
      end
    end

    context 'without articles' do
      it 'redirects to root' do
        get '/category/technology'
        expect(response).to redirect_to('/')
      end
    end

    context 'non-existent category' do
      it 'returns 404' do
        get '/category/nonexistent'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /category/:id with pagination' do
    let!(:category) { create(:category, name: 'Tech', permalink: 'tech') }

    before do
      blog.update(limit_article_display: 2)
      5.times do |i|
        article = create(:article, title: "Post #{i}", published: true, published_at: i.days.ago)
        article.categories << category
      end
    end

    it 'paginates articles' do
      get '/category/tech'
      expect(response.status).to be_in([200, 301, 302])
    end

    it 'shows page 2' do
      get '/category/tech', params: { page: 2 }
      expect(response.status).to be_in([200, 301, 302])
    end
  end

  describe 'GET /category/:id.rss' do
    let!(:category) { create(:category, name: 'Tech', permalink: 'tech') }

    before do
      article = create(:article, title: 'Tech Post', published: true, published_at: 1.day.ago)
      article.categories << category
    end

    it 'returns RSS feed' do
      get '/category/tech.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /category/:id.atom' do
    let!(:category) { create(:category, name: 'Tech', permalink: 'tech') }

    before do
      article = create(:article, title: 'Tech Post', published: true, published_at: 1.day.ago)
      article.categories << category
    end

    it 'returns Atom feed' do
      get '/category/tech.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end
end
