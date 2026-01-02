# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tags', type: :request do
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
    User.where(login: 'tag_author').destroy_all
    @user = User.create!(
      login: 'tag_author',
      email: 'tag@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Tag Author',
      profile: @profile,
      state: 'active'
    )
  end

  describe 'GET /tags (index)' do
    before do
      @tag1 = Tag.create!(name: 'ruby', display_name: 'Ruby')
      @tag2 = Tag.create!(name: 'rails', display_name: 'Rails')
    end

    it 'returns a successful response' do
      get '/tags'
      expect(response).to have_http_status(:success)
    end

    it 'displays tag names' do
      get '/tags'
      expect(response.body).to include('ruby')
    end
  end

  describe 'GET /tags with pagination' do
    before do
      105.times do |i|
        Tag.create!(name: "tag-#{i}", display_name: "Tag #{i}")
      end
    end

    it 'paginates tags on page 2' do
      get '/tags/page/2'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /tag/:id (show)' do
    before do
      @tag = Tag.create!(name: 'javascript', display_name: 'JavaScript')
      @article = Article.create!(
        title: 'JavaScript Article',
        body: 'JavaScript content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @article.tags << @tag
    end

    it 'returns a successful response' do
      get "/tag/#{@tag.name}"
      expect(response).to have_http_status(:success)
    end

    it 'displays articles with the tag' do
      get "/tag/#{@tag.name}"
      expect(response.body).to include('JavaScript Article')
    end

    context 'with pagination' do
      before do
        12.times do |i|
          article = Article.create!(
            title: "Tagged Article #{i}",
            body: "Content #{i}",
            published: true,
            user: @user,
            published_at: Time.now - i.hours
          )
          article.tags << @tag
        end
      end

      it 'paginates articles on page 2' do
        get "/tag/#{@tag.name}/page/2"
        expect(response).to have_http_status(:success)
      end
    end

    context 'empty tag' do
      before do
        @empty_tag = Tag.create!(name: 'empty-tag', display_name: 'Empty Tag')
      end

      it 'redirects to root for tag with no articles' do
        get "/tag/#{@empty_tag.name}"
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'GET /tag/:id.rss (RSS feed)' do
    before do
      @tag = Tag.create!(name: 'rss-tag', display_name: 'RSS Tag')
      @article = Article.create!(
        title: 'Tag RSS Article',
        body: 'RSS content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @article.tags << @tag
    end

    it 'returns a successful RSS response' do
      get "/tag/#{@tag.name}.rss"
      expect(response).to have_http_status(:success)
    end

    it 'returns RSS content type' do
      get "/tag/#{@tag.name}.rss"
      expect(response.media_type).to eq('application/rss+xml')
    end

    it 'includes article in RSS feed' do
      get "/tag/#{@tag.name}.rss"
      expect(response.body).to include('Tag RSS Article')
    end
  end

  describe 'GET /tag/:id.atom (Atom feed)' do
    before do
      @tag = Tag.create!(name: 'atom-tag', display_name: 'Atom Tag')
      @article = Article.create!(
        title: 'Tag Atom Article',
        body: 'Atom content',
        published: true,
        user: @user,
        published_at: Time.now
      )
      @article.tags << @tag
    end

    it 'returns a successful Atom response' do
      get "/tag/#{@tag.name}.atom"
      expect(response).to have_http_status(:success)
    end

    it 'returns Atom content type' do
      get "/tag/#{@tag.name}.atom"
      expect(response.media_type).to eq('application/atom+xml')
    end

    it 'includes article in Atom feed' do
      get "/tag/#{@tag.name}.atom"
      expect(response.body).to include('Tag Atom Article')
    end
  end

  describe 'non-existent tag' do
    it 'redirects for non-existent tag' do
      get '/tag/nonexistent-tag'
      expect(response).to redirect_to('/')
    end
  end
end
