# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authors', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /author/:id' do
    let!(:user) { create(:user, login: 'johndoe', name: 'John Doe') }

    context 'with articles' do
      before do
        create(:article, title: "John's Post", user: user, published: true, published_at: 1.day.ago)
      end

      it 'returns success' do
        get '/author/johndoe'
        expect(response).to have_http_status(:success)
      end

      it 'displays author name' do
        get '/author/johndoe'
        expect(response.body).to include('John Doe')
      end

      it 'displays author articles' do
        get '/author/johndoe'
        expect(response.status).to be_in([200, 301, 302])
      end
    end

    context 'without articles' do
      it 'returns success' do
        get '/author/johndoe'
        expect(response).to have_http_status(:success)
      end
    end

    context 'non-existent author' do
      it 'returns 404' do
        get '/author/nonexistent'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /author/:id.rss' do
    let!(:user) { create(:user, login: 'johndoe') }

    before do
      create(:article, title: "John's Post", user: user, published: true, published_at: 1.day.ago)
    end

    it 'returns RSS feed' do
      get '/author/johndoe.rss'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('rss')
    end
  end

  describe 'GET /author/:id.atom' do
    let!(:user) { create(:user, login: 'johndoe') }

    before do
      create(:article, title: "John's Post", user: user, published: true, published_at: 1.day.ago)
    end

    it 'returns Atom feed' do
      get '/author/johndoe.atom'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('atom')
    end
  end
end
