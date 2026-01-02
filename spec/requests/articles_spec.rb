# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Articles', type: :request do
  before(:each) do
    Blog.delete_all
    @blog = Blog.create!(
      base_url: 'http://test.host',
      blog_name: 'Test Blog',
      blog_subtitle: 'A test blog subtitle',
      theme: 'scribbish',
      limit_article_display: 10,
      limit_rss_display: 10,
      permalink_format: '/%year%/%month%/%day%/%title%'
    )
    Blog.instance_variable_set(:@default, @blog)

    @profile = Profile.find_or_create_by!(label: 'admin') do |p|
      p.nicename = 'Admin'
      p.modules = [:dashboard, :write, :articles]
    end
    User.where(login: 'test_author').destroy_all
    @user = User.create!(
      login: 'test_author',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Test Author',
      profile: @profile,
      state: 'active'
    )
  end

  describe 'GET / (index)' do
    context 'with published articles' do
      before do
        @article = Article.create!(
          title: 'Test Article',
          body: 'This is test content',
          published: true,
          user: @user,
          published_at: Time.now
        )
      end

      it 'returns a successful response' do
        get '/'
        expect(response).to have_http_status(:success)
      end

      it 'displays the article title' do
        get '/'
        expect(response.body).to include('Test Article')
      end

      it 'includes RSS feed link' do
        get '/'
        expect(response.body).to include('articles.rss')
      end

      it 'includes Atom feed link' do
        get '/'
        expect(response.body).to include('articles.atom')
      end
    end

    context 'with no articles' do
      it 'returns a successful response with empty message' do
        get '/'
        expect(response).to have_http_status(:success)
      end
    end

    context 'with pagination' do
      before do
        15.times do |i|
          Article.create!(
            title: "Article #{i}",
            body: "Article content #{i}",
            published: true,
            user: @user,
            published_at: Time.now - i.days
          )
        end
      end

      it 'paginates articles on page 2' do
        get '/page/2'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /articles.rss (RSS feed)' do
    before do
      @article = Article.create!(
        title: 'RSS Article',
        body: 'RSS content',
        published: true,
        user: @user,
        published_at: Time.now
      )
    end

    it 'returns a successful RSS response' do
      get '/articles.rss'
      expect(response).to have_http_status(:success)
    end

    it 'returns RSS content type' do
      get '/articles.rss'
      expect(response.media_type).to eq('application/rss+xml')
    end

    it 'includes article in RSS feed' do
      get '/articles.rss'
      expect(response.body).to include('RSS Article')
    end
  end

  describe 'GET /articles.atom (Atom feed)' do
    before do
      @article = Article.create!(
        title: 'Atom Article',
        body: 'Atom content',
        published: true,
        user: @user,
        published_at: Time.now
      )
    end

    it 'returns a successful Atom response' do
      get '/articles.atom'
      expect(response).to have_http_status(:success)
    end

    it 'returns Atom content type' do
      get '/articles.atom'
      expect(response.media_type).to eq('application/atom+xml')
    end

    it 'includes article in Atom feed' do
      get '/articles.atom'
      expect(response.body).to include('Atom Article')
    end
  end

  describe 'GET /archives' do
    before do
      @article = Article.create!(
        title: 'Archived Article',
        body: 'Archive content',
        published: true,
        user: @user,
        published_at: Time.now
      )
    end

    it 'returns a successful response' do
      get '/archives/'
      expect(response).to have_http_status(:success)
    end

    it 'displays archived articles' do
      get '/archives/'
      expect(response.body).to include('Archived Article')
    end

    it 'includes Archives in title' do
      get '/archives/'
      expect(response.body).to include('Archives')
    end
  end

  describe 'GET /search' do
    before do
      @article = Article.create!(
        title: 'Searchable Article',
        body: 'This article contains unique keywords',
        published: true,
        user: @user,
        published_at: Time.now
      )
    end

    context 'with matching results' do
      it 'returns a successful response' do
        get '/search/unique'
        expect(response).to have_http_status(:success)
      end

      it 'displays matching articles' do
        get '/search/unique'
        expect(response.body).to include('Searchable Article')
      end
    end

    context 'with no results' do
      it 'returns a successful response with no results message' do
        get '/search/nonexistent_term_xyz'
        expect(response).to have_http_status(:success)
      end
    end

    context 'RSS format' do
      it 'returns RSS feed for search results' do
        get '/search/unique.rss'
        expect(response).to have_http_status(:success)
      end
    end

    context 'Atom format' do
      it 'returns Atom feed for search results' do
        get '/search/unique.atom'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /live_search' do
    before do
      @article = Article.create!(
        title: 'Live Search Article',
        body: 'Searchable content for live search',
        published: true,
        user: @user,
        published_at: Time.now
      )
    end

    it 'returns a successful response' do
      get '/live_search/', params: { q: 'Live' }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /:year/:month (monthly archives)' do
    before do
      @article = Article.create!(
        title: 'Monthly Article',
        body: 'Monthly content',
        published: true,
        user: @user,
        published_at: Time.utc(2024, 6, 15)
      )
    end

    it 'returns a successful response' do
      get '/2024/6'
      expect(response).to have_http_status(:success)
    end

    it 'displays articles from that month' do
      get '/2024/6'
      expect(response.body).to include('Monthly Article')
    end
  end

  describe 'GET /:year (yearly archives)' do
    before do
      @article = Article.create!(
        title: 'Yearly Article',
        body: 'Yearly content',
        published: true,
        user: @user,
        published_at: Time.utc(2024, 3, 10)
      )
    end

    it 'returns a successful response' do
      get '/2024'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET article by permalink' do
    before do
      @article = Article.create!(
        title: 'Permalink Article',
        permalink: 'permalink-article',
        body: 'Article body content',
        published: true,
        user: @user,
        published_at: Time.utc(2024, 1, 15),
        created_at: Time.utc(2024, 1, 15),
        updated_at: Time.utc(2024, 1, 15)
      )
    end

    it 'returns a successful response' do
      get '/2024/01/15/permalink-article'
      expect(response).to have_http_status(:success)
    end

    it 'displays the article content' do
      get '/2024/01/15/permalink-article'
      expect(response.body).to include('Permalink Article')
    end

    it 'displays the article body' do
      get '/2024/01/15/permalink-article'
      expect(response.body).to include('Article body content')
    end
  end

  describe 'GET /pages/:name' do
    before do
      @page = Page.create!(
        name: 'about',
        title: 'About Us',
        body: 'About page content',
        published: true,
        user: @user
      )
    end

    it 'returns a successful response' do
      get '/pages/about'
      expect(response).to have_http_status(:success)
    end

    it 'displays the page title' do
      get '/pages/about'
      expect(response.body).to include('About Us')
    end

    it 'displays the page content' do
      get '/pages/about'
      expect(response.body).to include('About page content')
    end

    it 'returns 404 for non-existent page' do
      get '/pages/nonexistent'
      expect(response).to have_http_status(:not_found)
    end
  end
end
