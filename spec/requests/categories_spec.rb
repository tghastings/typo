# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Categories', type: :request do
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
    User.where(login: 'category_author').destroy_all
    @user = User.create!(
      login: 'category_author',
      email: 'category@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Category Author',
      profile: @profile,
      state: 'active'
    )
  end

  describe 'GET /categories (index)' do
    before do
      @category1 = Category.create!(name: 'Technology', permalink: 'technology')
      @category2 = Category.create!(name: 'Science', permalink: 'science')
    end

    it 'returns a successful response' do
      get '/categories'
      expect(response).to have_http_status(:success)
    end

    it 'displays category names' do
      get '/categories'
      expect(response.body).to include('Technology')
      expect(response.body).to include('Science')
    end
  end

  describe 'GET /category/:id (show)' do
    before do
      @category = Category.create!(name: 'Programming', permalink: 'programming')
      @article = Article.create!(
        title: 'Programming Article',
        body: 'Programming content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @article.categories << @category
    end

    it 'returns a successful response' do
      get "/category/#{@category.permalink}"
      expect(response).to have_http_status(:success)
    end

    it 'displays articles in the category' do
      get "/category/#{@category.permalink}"
      expect(response.body).to include('Programming Article')
    end

    it 'displays the category name' do
      get "/category/#{@category.permalink}"
      expect(response.body).to include('Programming')
    end

    context 'with pagination' do
      before do
        12.times do |i|
          article = Article.create!(
            title: "Category Article #{i}",
            body: "Content #{i}",
            published: true,
            user: @user,
            published_at: Time.now - i.hours
          )
          article.categories << @category
        end
      end

      it 'paginates articles on page 2' do
        get "/category/#{@category.permalink}/page/2"
        expect(response).to have_http_status(:success)
      end
    end

    context 'empty category' do
      before do
        @empty_category = Category.create!(name: 'Empty', permalink: 'empty')
      end

      it 'redirects to root for empty category' do
        get "/category/#{@empty_category.permalink}"
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'GET /category/:id.rss (RSS feed)' do
    before do
      @category = Category.create!(name: 'RSS Category', permalink: 'rss-category')
      @article = Article.create!(
        title: 'Category RSS Article',
        body: 'RSS content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @article.categories << @category
    end

    it 'returns a successful RSS response' do
      get "/category/#{@category.permalink}.rss"
      expect(response).to have_http_status(:success)
    end

    it 'returns RSS content type' do
      get "/category/#{@category.permalink}.rss"
      expect(response.media_type).to eq('application/rss+xml')
    end

    it 'includes article in RSS feed' do
      get "/category/#{@category.permalink}.rss"
      expect(response.body).to include('Category RSS Article')
    end
  end

  describe 'GET /category/:id.atom (Atom feed)' do
    before do
      @category = Category.create!(name: 'Atom Category', permalink: 'atom-category')
      @article = Article.create!(
        title: 'Category Atom Article',
        body: 'Atom content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @article.categories << @category
    end

    it 'returns a successful Atom response' do
      get "/category/#{@category.permalink}.atom"
      expect(response).to have_http_status(:success)
    end

    it 'returns Atom content type' do
      get "/category/#{@category.permalink}.atom"
      expect(response.media_type).to eq('application/atom+xml')
    end

    it 'includes article in Atom feed' do
      get "/category/#{@category.permalink}.atom"
      expect(response.body).to include('Category Atom Article')
    end
  end

  describe 'non-existent category' do
    it 'returns 404 for non-existent category' do
      get '/category/nonexistent-category'
      expect(response).to have_http_status(:not_found)
    end
  end
end
