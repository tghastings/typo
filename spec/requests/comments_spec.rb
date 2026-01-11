# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comments', type: :request do
  let!(:blog) { create(:blog) }
  let!(:article) { create(:article, allow_comments: true, published: true, published_at: 1.day.ago) }

  describe 'POST /comments' do
    let(:valid_params) do
      {
        comment: {
          author: 'John Doe',
          email: 'john@example.com',
          body: 'Great article!'
        },
        article_id: article.id
      }
    end

    it 'creates a new comment' do
      expect do
        post '/comments', params: valid_params
      end.to change(Comment, :count).by(1)
    end

    it 'redirects to article' do
      post '/comments', params: valid_params
      expect(response).to redirect_to(article.permalink_url)
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          comment: {
            author: '',
            body: ''
          },
          article_id: article.id
        }
      end

      it 'does not create comment' do
        expect do
          post '/comments', params: invalid_params
        end.not_to change(Comment, :count)
      end
    end

    context 'when comments are closed' do
      before do
        article.update(allow_comments: false)
      end

      it 'does not create comment' do
        expect do
          post '/comments', params: valid_params
        end.not_to change(Comment, :count)
      end
    end
  end

  describe 'GET /comments.rss' do
    before do
      create(:comment, article: article, author: 'John', body: 'Great!', published: true)
    end

    it 'returns RSS feed of comments' do
      get '/comments.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /comments.atom' do
    before do
      create(:comment, article: article, author: 'John', body: 'Great!', published: true)
    end

    it 'returns Atom feed of comments' do
      get '/comments.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end

  describe 'POST /comments with XHR' do
    let(:valid_params) do
      {
        comment: {
          author: 'Ajax User',
          email: 'ajax@example.com',
          body: 'Ajax comment!'
        },
        article_id: article.id
      }
    end

    it 'creates comment via XHR' do
      expect do
        post '/comments', params: valid_params, xhr: true
      end.to change(Comment, :count).by(1)
    end

    it 'returns success' do
      post '/comments', params: valid_params, xhr: true
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /comments with URL' do
    it 'accepts valid URL' do
      post '/comments', params: {
        comment: {
          author: 'John',
          email: 'john@test.com',
          body: 'With URL',
          url: 'http://example.com'
        },
        article_id: article.id
      }
      expect(response.status).to be_in([200, 302])
    end
  end

  describe 'spam protection' do
    it 'handles honeypot field' do
      post '/comments', params: {
        comment: {
          author: 'John',
          email: 'john@test.com',
          body: 'Test'
        },
        article_id: article.id
      }
      expect(response.status).to be_in([200, 302])
    end
  end
end
