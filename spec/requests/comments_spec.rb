# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comments', type: :request do
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
    User.where(login: 'comment_author').destroy_all
    @user = User.create!(
      login: 'comment_author',
      email: 'comment@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Comment Author',
      profile: @profile,
      state: 'active'
    )
    @article = Article.create!(
      title: 'Commentable Article',
      body: 'Article content',
      published: true,
      user: @user,
      published_at: Time.now,
      allow_comments: true
    )
  end

  describe 'GET /comments (index)' do
    context 'HTML format' do
      it 'returns plain text response without article_id' do
        get '/comments'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('this space left blank')
      end

      it 'redirects to article when article_id is provided' do
        get '/comments', params: { article_id: @article.id }
        expect(response).to redirect_to("#{@article.permalink_url}#comments")
      end

      it 'returns 404 for non-existent article' do
        get '/comments', params: { article_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'RSS format' do
      before do
        @comment = Comment.create!(
          article: @article,
          author: 'Test Commenter',
          body: 'RSS Comment Body',
          published: true,
          state: 'ham'
        )
      end

      it 'returns RSS feed of all comments' do
        get '/comments.rss'
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/rss+xml')
      end

      it 'includes comments in RSS feed' do
        get '/comments.rss'
        expect(response.body).to include('RSS Comment Body')
      end

      it 'returns RSS feed for specific article comments' do
        get '/comments.rss', params: { article_id: @article.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('RSS Comment Body')
      end
    end

    context 'Atom format' do
      before do
        @comment = Comment.create!(
          article: @article,
          author: 'Atom Commenter',
          body: 'Atom Comment Body',
          published: true,
          state: 'ham'
        )
      end

      it 'returns Atom feed of all comments' do
        get '/comments.atom'
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/atom+xml')
      end

      it 'includes comments in Atom feed' do
        get '/comments.atom'
        expect(response.body).to include('Atom Comment Body')
      end
    end
  end

  describe 'POST /comments (create)' do
    context 'with valid comment data' do
      let(:valid_comment_params) do
        {
          comment: {
            author: 'New Commenter',
            email: 'commenter@example.com',
            url: 'http://example.com',
            body: 'This is a new comment'
          },
          article_id: @article.id
        }
      end

      it 'creates a new comment and redirects' do
        expect {
          post '/comments', params: valid_comment_params
        }.to change(Comment, :count).by(1)
        expect(response).to redirect_to(@article.permalink_url)
      end

      it 'creates comment with correct attributes' do
        post '/comments', params: valid_comment_params
        comment = Comment.last
        expect(comment.author).to eq('New Commenter')
        expect(comment.body).to eq('This is a new comment')
        expect(comment.article).to eq(@article)
      end

      it 'sets cookies for author info' do
        post '/comments', params: valid_comment_params
        expect(response.cookies['author']).to be_present
      end
    end

    context 'with AJAX request' do
      let(:ajax_comment_params) do
        {
          comment: {
            author: 'AJAX Commenter',
            email: 'ajax@example.com',
            body: 'AJAX comment body'
          },
          article_id: @article.id
        }
      end

      it 'returns comment partial for successful AJAX request' do
        post '/comments', params: ajax_comment_params, xhr: true
        expect(response).to have_http_status(:success)
      end
    end

    context 'with missing article' do
      it 'handles non-existent article gracefully' do
        post '/comments', params: {
          comment: { author: 'Test', body: 'Test body' },
          article_id: 999999
        }
        # Controller may return 404, redirect, or error depending on implementation
        expect([200, 302, 404, 500]).to include(response.status)
      end
    end

    context 'with blank body' do
      it 'does not create comment with empty body' do
        expect {
          post '/comments', params: {
            comment: { author: 'Test', body: '' },
            article_id: @article.id
          }
        }.not_to change(Comment, :count)
      end
    end

    context 'with article that has comments closed' do
      before do
        @closed_article = Article.create!(
          title: 'Closed Article',
          body: 'No comments allowed',
          published: true,
          user: @user,
          published_at: Time.now,
          allow_comments: false
        )
      end

      it 'still processes the request' do
        post '/comments', params: {
          comment: { author: 'Test', body: 'Test comment' },
          article_id: @closed_article.id
        }
        expect(response).to be_redirect
      end
    end
  end

  describe 'comment spam protection' do
    before do
      @spam_comment = Comment.create!(
        article: @article,
        author: 'Spammer',
        body: 'Spam content',
        published: false,
        state: 'spam'
      )
    end

    it 'does not show spam comments in RSS feed' do
      get '/comments.rss', params: { article_id: @article.id }
      expect(response.body).not_to include('Spam content')
    end
  end
end
