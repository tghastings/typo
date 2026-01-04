# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'XML Feeds', type: :request do
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
      p.modules = %i[dashboard write articles]
    end
    User.where(login: 'xml_author').destroy_all
    @user = User.create!(
      login: 'xml_author',
      email: 'xml@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'XML Author',
      profile: @profile,
      state: 'active'
    )
  end

  describe 'GET /xml/rss (RSS feed redirect)' do
    it 'redirects to articles RSS feed' do
      get '/xml/rss'
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(rss_url)
    end
  end

  describe 'GET /xml/rss/feed.xml' do
    it 'redirects to articles RSS feed' do
      get '/xml/rss/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(rss_url)
    end
  end

  describe 'GET /xml/atom/feed.xml' do
    it 'redirects to articles Atom feed' do
      get '/xml/atom/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(atom_url)
    end
  end

  describe 'GET /xml/rsd' do
    it 'returns a successful RSD response' do
      get '/xml/rsd'
      expect(response).to have_http_status(:success)
    end

    it 'includes RSD content' do
      get '/xml/rsd'
      expect(response.body).to include('rsd')
    end
  end

  describe 'GET /sitemap.xml (Google Sitemap)' do
    before do
      @article = Article.create!(
        title: 'Sitemap Article',
        body: 'Sitemap content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @page = Page.create!(
        name: 'sitemap-page',
        title: 'Sitemap Page',
        body: 'Page content',
        published: true,
        user: @user
      )
    end

    it 'returns a successful sitemap response' do
      get '/sitemap.xml'
      expect(response).to have_http_status(:success)
    end

    it 'returns XML content type' do
      get '/sitemap.xml'
      expect(response.media_type).to eq('application/xml')
    end

    it 'includes urlset element in sitemap' do
      get '/sitemap.xml'
      expect(response.body).to include('urlset')
    end
  end

  describe 'GET /xml/articlerss/:id/feed.xml' do
    before do
      @article = Article.create!(
        title: 'Article RSS Feed',
        body: 'Article content',
        published: true,
        user: @user,
        published_at: Time.now
      )
    end

    it 'redirects to article RSS feed' do
      get "/xml/articlerss/#{@article.id}/feed.xml"
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'returns 404 for non-existent article' do
      get '/xml/articlerss/999999/feed.xml'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /xml/commentrss/feed.xml' do
    it 'redirects to comments RSS feed' do
      get '/xml/commentrss/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'GET /xml/trackbackrss/feed.xml' do
    it 'redirects to trackbacks RSS feed' do
      get '/xml/trackbackrss/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'GET /xml/:format/category/:id/feed.xml' do
    before do
      @category = Category.create!(name: 'XML Category', permalink: 'xml-category')
    end

    it 'redirects to category RSS feed' do
      get "/xml/rss/category/#{@category.permalink}/feed.xml"
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'redirects to category Atom feed' do
      get "/xml/atom/category/#{@category.permalink}/feed.xml"
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'GET /xml/:format/tag/:id/feed.xml' do
    before do
      @tag = Tag.create!(name: 'xml-tag', display_name: 'XML Tag')
    end

    it 'redirects to tag RSS feed' do
      get "/xml/rss/tag/#{@tag.name}/feed.xml"
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'redirects to tag Atom feed' do
      get "/xml/atom/tag/#{@tag.name}/feed.xml"
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'GET /xml/:format/trackbacks/feed.xml' do
    it 'redirects to trackbacks RSS feed' do
      get '/xml/rss/trackbacks/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'redirects to trackbacks Atom feed' do
      get '/xml/atom/trackbacks/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'GET /xml/:format/comments/feed.xml' do
    it 'redirects to comments RSS feed' do
      get '/xml/rss/comments/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'redirects to comments Atom feed' do
      get '/xml/atom/comments/feed.xml'
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe 'unsupported format handling' do
    it 'returns 404 for unsupported format' do
      get '/xml/unsupported/feed.xml'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'unsupported feed type handling' do
    it 'returns 404 for unsupported feed type' do
      get '/xml/feed', params: { format: 'rss', type: 'unsupported' }
      expect(response).to have_http_status(:not_found)
    end
  end
end
