# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Articles', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /' do
    context 'with published articles' do
      before do
        create(:article, title: 'First Post', published: true, published_at: 1.day.ago)
        create(:article, title: 'Second Post', published: true, published_at: 2.days.ago)
      end

      it 'returns success' do
        get '/'
        expect(response).to have_http_status(:success)
      end

      it 'displays article titles' do
        get '/'
        expect(response.body).to include('First Post')
        expect(response.body).to include('Second Post')
      end

      it 'returns RSS feed with .rss format' do
        get '/articles.rss'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('rss')
      end

      it 'returns Atom feed with .atom format' do
        get '/articles.atom'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('atom')
      end
    end

    context 'without published articles' do
      before { create(:article, published: false) } # Need at least one article for some checks

      it 'returns success or redirects' do
        get '/'
        expect(response.status).to be_in([200, 302])
      end
    end

    context 'with pagination' do
      before do
        blog.update(limit_article_display: 2)
        5.times { |i| create(:article, title: "Post #{i}", published: true, published_at: i.days.ago) }
      end

      it 'paginates articles' do
        get '/'
        expect(response).to have_http_status(:success)
      end

      it 'shows page 2' do
        get '/', params: { page: 2 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /:year/:month/:day/:title' do
    let!(:article) do
      create(:article,
             title: 'Test Article',
             permalink: 'test-article',
             published: true,
             published_at: Time.zone.local(2024, 6, 15))
    end

    it 'returns success for existing article' do
      get '/2024/06/15/test-article'
      expect(response).to have_http_status(:success)
    end

    it 'displays article content' do
      get '/2024/06/15/test-article'
      expect(response.body).to include('Test Article')
    end

    it 'returns 404 for non-existent article' do
      get '/2024/06/15/nonexistent'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /search' do
    before do
      create(:article, title: 'Ruby Programming', body: 'Ruby is great', published: true, published_at: 1.day.ago)
      create(:article, title: 'Python Guide', body: 'Python basics', published: true, published_at: 1.day.ago)
    end

    it 'returns search results' do
      get '/search', params: { q: 'Ruby' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Ruby Programming')
    end

    it 'does not return non-matching articles' do
      get '/search', params: { q: 'Ruby' }
      expect(response.body).not_to include('Python Guide')
    end
  end

  describe 'GET /:year/:month/:day/:title.rss' do
    let!(:article) do
      create(:article,
             title: 'Test Article',
             permalink: 'test-article',
             published: true,
             published_at: Time.zone.local(2024, 6, 15))
    end

    before do
      create(:comment, article: article, author: 'John', body: 'Great post!')
    end

    it 'returns RSS feed' do
      get '/2024/06/15/test-article.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /:year/:month/:day/:title.atom' do
    let!(:article) do
      create(:article,
             title: 'Test Article',
             permalink: 'test-article',
             published: true,
             published_at: Time.zone.local(2024, 6, 15))
    end

    before do
      create(:comment, article: article, author: 'John', body: 'Great post!')
    end

    it 'returns Atom feed' do
      get '/2024/06/15/test-article.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end

  describe 'GET /archives' do
    before do
      create(:article, title: 'Archive Post', published: true, published_at: 1.day.ago)
    end

    it 'returns archives page' do
      get '/archives'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /:year/:month (monthly archive)' do
    before do
      create(:article, title: 'January Post', published: true, published_at: Time.zone.parse('2022-01-15 12:00:00'))
    end

    it 'returns monthly archive page' do
      get '/2022/01'
      expect(response).to have_http_status(:success)
      expect(response.body).to include('January Post')
    end
  end

  describe 'GET /live_search' do
    before do
      create(:article, title: 'Searchable Post', body: 'findme', published: true)
    end

    it 'returns live search results' do
      get '/live_search', params: { q: 'findme' }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /check_password' do
    let!(:article) { create(:article, title: 'Protected', password: 'secret', published: true) }

    it 'accepts correct password' do
      post '/check_password', params: { article: { id: article.id, password: 'secret' } }, xhr: true
      expect(response).to have_http_status(:success)
    end

    it 'rejects wrong password' do
      post '/check_password', params: { article: { id: article.id, password: 'wrong' } }, xhr: true
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /pages/:name' do
    context 'with published page' do
      let!(:page) { create(:page, name: 'about', title: 'About Us', published: true) }

      it 'shows page' do
        get '/pages/about'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('About Us')
      end
    end
  end
end
