# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authors', type: :request do
  before(:each) do
    Blog.delete_all
    @blog = Blog.create!(
      base_url: 'http://test.host',
      blog_name: 'Test Blog',
      blog_subtitle: 'A test blog subtitle',
      theme: 'typographic',
      limit_article_display: 10,
      limit_rss_display: 10,
      permalink_format: '/%year%/%month%/%day%/%title%'
    )
    Blog.instance_variable_set(:@default, @blog)

    @profile = Profile.find_or_create_by!(label: 'admin') do |p|
      p.nicename = 'Admin'
      p.modules = [:dashboard, :write, :articles]
    end
    User.where(login: 'author_user').destroy_all
    @author = User.create!(
      login: 'author_user',
      email: 'author@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Author Name',
      profile: @profile,
      state: 'active'
    )
  end

  describe 'GET /author/:id (show)' do
    before do
      @article = Article.create!(
        title: 'Author Article',
        body: 'Article by author',
        published: true,
        user: @author,
        published_at: Time.now
      )
    end

    it 'returns a successful response' do
      get "/author/#{@author.login}"
      expect(response).to have_http_status(:success)
    end

    it 'displays the author login' do
      get "/author/#{@author.login}"
      expect(response.body).to include(@author.login)
    end

    it 'displays articles by the author' do
      get "/author/#{@author.login}"
      expect(response.body).to include('Author Article')
    end

    it 'includes RSS feed link' do
      get "/author/#{@author.login}"
      expect(response.body).to include("author/#{@author.login}.rss")
    end

    it 'includes Atom feed link' do
      get "/author/#{@author.login}"
      expect(response.body).to include("author/#{@author.login}.atom")
    end
  end

  describe 'GET /author/:id.rss (RSS feed)' do
    before do
      @article = Article.create!(
        title: 'Author RSS Article',
        body: 'RSS content by author',
        published: true,
        user: @author,
        published_at: Time.now
      )
    end

    it 'returns a successful RSS response' do
      get "/author/#{@author.login}.rss"
      expect(response).to have_http_status(:success)
    end

    it 'returns RSS content type' do
      get "/author/#{@author.login}.rss"
      expect(response.media_type).to eq('application/rss+xml')
    end

    it 'includes article in RSS feed' do
      get "/author/#{@author.login}.rss"
      expect(response.body).to include('Author RSS Article')
    end
  end

  describe 'GET /author/:id.atom (Atom feed)' do
    before do
      @article = Article.create!(
        title: 'Author Atom Article',
        body: 'Atom content by author',
        published: true,
        user: @author,
        published_at: Time.now
      )
    end

    it 'returns a successful Atom response' do
      get "/author/#{@author.login}.atom"
      expect(response).to have_http_status(:success)
    end

    it 'returns Atom content type' do
      get "/author/#{@author.login}.atom"
      expect(response.media_type).to eq('application/atom+xml')
    end

    it 'includes article in Atom feed' do
      get "/author/#{@author.login}.atom"
      expect(response.body).to include('Author Atom Article')
    end
  end

  describe 'non-existent author' do
    it 'returns 404 for non-existent author' do
      get '/author/nonexistent_author'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'author with multiple articles' do
    before do
      5.times do |i|
        Article.create!(
          title: "Multi Article #{i}",
          body: "Content #{i}",
          published: true,
          user: @author,
          published_at: Time.now - i.days
        )
      end
    end

    it 'displays all articles by the author' do
      get "/author/#{@author.login}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Multi Article 0')
      expect(response.body).to include('Multi Article 4')
    end
  end

  describe 'author with unpublished articles' do
    before do
      @published = Article.create!(
        title: 'Published Article',
        body: 'Published content',
        published: true,
        user: @author,
        published_at: Time.now
      )
      @unpublished = Article.create!(
        title: 'Unpublished Article',
        body: 'Unpublished content',
        published: false,
        user: @author,
        published_at: nil
      )
    end

    it 'only displays published articles' do
      get "/author/#{@author.login}"
      expect(response.body).to include('Published Article')
      expect(response.body).not_to include('Unpublished Article')
    end
  end
end
