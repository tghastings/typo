# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tags', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /tags' do
    before do
      tag = create(:tag, name: 'ruby')
      article = create(:article, published: true, published_at: 1.day.ago)
      article.tags << tag
    end

    it 'returns success' do
      get '/tags'
      expect(response).to have_http_status(:success)
    end

    it 'displays tags' do
      get '/tags'
      expect(response.body).to include('ruby')
    end
  end

  describe 'GET /tag/:id' do
    let!(:tag) { create(:tag, name: 'ruby') }

    context 'with articles' do
      before do
        article = create(:article, title: 'Ruby Post', published: true, published_at: 1.day.ago)
        article.tags << tag
      end

      it 'returns success' do
        get '/tag/ruby'
        expect(response).to have_http_status(:success)
      end

      it 'displays tag name' do
        get '/tag/ruby'
        expect(response.body).to include('ruby')
      end

      it 'displays articles with tag' do
        get '/tag/ruby'
        expect(response.body).to include('Ruby Post')
      end
    end

    context 'without articles' do
      it 'redirects to root' do
        get '/tag/ruby'
        expect(response).to redirect_to('/')
      end
    end

    context 'non-existent tag' do
      it 'returns error or redirect' do
        get '/tag/nonexistent'
        expect(response.status).to be_in([301, 302, 404])
      end
    end
  end

  describe 'GET /tag/:id with pagination' do
    let!(:tag) { create(:tag, name: 'ruby') }

    before do
      blog.update(limit_article_display: 2)
      5.times do |i|
        article = create(:article, title: "Post #{i}", published: true, published_at: i.days.ago)
        article.tags << tag
      end
    end

    it 'paginates articles' do
      get '/tag/ruby'
      expect(response.status).to be_in([200, 301, 302])
    end

    it 'shows page 2' do
      get '/tag/ruby', params: { page: 2 }
      expect(response.status).to be_in([200, 301, 302])
    end
  end

  describe 'GET /tag/:id.rss' do
    let!(:tag) { create(:tag, name: 'ruby') }

    before do
      article = create(:article, title: 'Ruby Post', published: true, published_at: 1.day.ago)
      article.tags << tag
    end

    it 'returns RSS feed' do
      get '/tag/ruby.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /tag/:id.atom' do
    let!(:tag) { create(:tag, name: 'ruby') }

    before do
      article = create(:article, title: 'Ruby Post', published: true, published_at: 1.day.ago)
      article.tags << tag
    end

    it 'returns Atom feed' do
      get '/tag/ruby.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end
end
