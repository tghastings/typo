# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trackbacks', type: :request do
  before(:each) do
    Blog.delete_all
    @blog = Blog.create!(
      base_url: 'http://test.host',
      blog_name: 'Test Blog',
      blog_subtitle: 'A test blog subtitle',
      theme: 'scribbish',
      limit_article_display: 10,
      limit_rss_display: 10,
      permalink_format: '/%year%/%month%/%day%/%title%',
      global_pings_disable: false
    )
    Blog.instance_variable_set(:@default, @blog)

    @profile = Profile.find_or_create_by!(label: 'admin') do |p|
      p.nicename = 'Admin'
      p.modules = %i[dashboard write articles]
    end
    User.where(login: 'trackback_author').destroy_all
    @user = User.create!(
      login: 'trackback_author',
      email: 'trackback@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Trackback Author',
      profile: @profile,
      state: 'active'
    )
    @article = Article.create!(
      title: 'Trackbackable Article',
      body: 'Article content',
      published: true,
      user: @user,
      published_at: Time.now,
      allow_pings: true
    )
  end

  describe 'GET /trackbacks (index)' do
    context 'HTML format' do
      it 'returns plain text response without article_id' do
        get '/trackbacks'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('this space left blank')
      end

      it 'redirects to article when article_id is provided' do
        get '/trackbacks', params: { article_id: @article.id }
        expect(response).to redirect_to("#{@article.permalink_url}#trackbacks")
      end
    end

    context 'RSS format' do
      before do
        @trackback = Trackback.create!(
          article: @article,
          blog_name: 'External Blog',
          title: 'Trackback Title',
          excerpt: 'Trackback excerpt content',
          url: 'http://external.example.com/post',
          published: true,
          state: 'ham'
        )
      end

      it 'returns RSS feed of trackbacks' do
        get '/trackbacks.rss'
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/rss+xml')
      end

      it 'includes trackbacks in RSS feed' do
        get '/trackbacks.rss'
        expect(response.body).to include('Trackback Title')
      end
    end

    context 'Atom format' do
      before do
        @trackback = Trackback.create!(
          article: @article,
          blog_name: 'Atom Blog',
          title: 'Atom Trackback',
          excerpt: 'Atom trackback content',
          url: 'http://atom.example.com/post',
          published: true,
          state: 'ham'
        )
      end

      it 'returns Atom feed of trackbacks' do
        get '/trackbacks.atom'
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/atom+xml')
      end

      it 'includes trackbacks in Atom feed' do
        get '/trackbacks.atom'
        expect(response.body).to include('Atom Trackback')
      end
    end
  end

  describe 'POST /trackbacks (create)' do
    context 'when pings are disabled' do
      before do
        @blog.global_pings_disable = true
        @blog.save!
      end

      it 'does not create trackback' do
        expect do
          post '/trackbacks', params: {
            id: @article.id,
            url: 'http://external.example.com/linking-post',
            blog_name: 'External Blog',
            title: 'Linking Post Title',
            excerpt: 'This post links to your article'
          }
        end.not_to change(Trackback, :count)
      end

      it 'returns XML response with error' do
        post '/trackbacks', params: {
          id: @article.id,
          url: 'http://external.example.com/linking-post',
          format: :xml
        }
        # Verify XML response contains error info
        expect(response.body).to include('error')
      end
    end
  end

  describe 'trackback spam handling' do
    before do
      @spam_trackback = Trackback.create!(
        article: @article,
        blog_name: 'Spam Blog',
        title: 'Spam Trackback',
        excerpt: 'Spam content',
        url: 'http://spam.example.com',
        published: false,
        state: 'spam'
      )
    end

    it 'does not show spam trackbacks in RSS feed' do
      get '/trackbacks.rss'
      expect(response.body).not_to include('Spam Trackback')
    end
  end
end
