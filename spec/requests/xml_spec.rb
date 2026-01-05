# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'XML Feeds', type: :request do
  let!(:blog) { create(:blog) }

  before do
    create(:article, title: 'Test Post', published: true, published_at: 1.day.ago)
  end

  describe 'GET /articles.rss' do
    it 'returns RSS feed' do
      get '/articles.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end

    it 'includes article title' do
      get '/articles.rss'
      expect(response.body).to include('Test Post')
    end
  end

  describe 'GET /articles.atom' do
    it 'returns Atom feed' do
      get '/articles.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end

    it 'includes article title' do
      get '/articles.atom'
      expect(response.body).to include('Test Post')
    end
  end

  describe 'GET /comments.rss' do
    before do
      article = Article.first
      create(:comment, article: article, author: 'John', body: 'Great post!', published: true)
    end

    it 'returns RSS feed of comments' do
      get '/comments.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /comments.atom' do
    before do
      article = Article.first
      create(:comment, article: article, author: 'John', body: 'Great post!', published: true)
    end

    it 'returns Atom feed of comments' do
      get '/comments.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end

  describe 'GET /trackbacks.rss' do
    before do
      article = Article.first
      create(:trackback, article: article, published: true)
    end

    it 'returns RSS feed of trackbacks' do
      get '/trackbacks.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /trackbacks.atom' do
    before do
      article = Article.first
      create(:trackback, article: article, published: true)
    end

    it 'returns Atom feed of trackbacks' do
      get '/trackbacks.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end

  describe 'XmlController#feed' do
    describe 'type=sitemap' do
      let!(:category) { create(:category, name: 'Tech') }
      let!(:tag) { create(:tag, name: 'ruby') }
      let!(:page) { create(:page, title: 'About', published: true) }

      before do
        Article.first.categories << category
        Article.first.tags << tag
      end

      it 'returns googlesitemap format' do
        get '/sitemap.xml'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('xml')
      end

      it 'includes articles in sitemap' do
        get '/sitemap.xml'
        expect(response.body).to include('url')
      end
    end
  end

  describe 'XmlController#articlerss' do
    let!(:article) { Article.first }

    it 'redirects to article rss feed' do
      get "/xml/articlerss/#{article.id}/feed.xml"
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'returns 404 for non-existent article' do
      get '/xml/articlerss/99999/feed.xml'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'XmlController#commentrss' do
    it 'redirects to comments rss feed' do
      get '/xml/commentrss/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'XmlController#trackbackrss' do
    it 'redirects to trackbacks rss feed' do
      get '/xml/trackbackrss/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'XmlController#rsd' do
    it 'returns RSD document' do
      get '/xml/rsd'
      expect(response).to have_http_status(:success)
    end
  end
end
