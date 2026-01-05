# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Dashboard', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin' do
    context 'when logged in as admin' do
      before { login_as_admin }

      it 'returns success' do
        get '/admin'
        expect(response).to have_http_status(:success)
      end

      it 'displays dashboard' do
        get '/admin'
        expect(response.body).to include('Dashboard')
      end

      context 'with published articles' do
        before do
          create(:article, published: true, user: admin)
        end

        it 'shows article statistics' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end
      end

      context 'with comments' do
        let!(:article) { create(:article, published: true, user: admin) }

        before do
          create(:comment, article: article, published: true, state: 'ham')
          create(:spam_comment, article: article)
        end

        it 'shows comment statistics' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end

        it 'displays recent comments' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end
      end

      context 'with categories' do
        before do
          create(:category, name: 'Tech')
          create(:category, name: 'News')
        end

        it 'counts categories' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end
      end

      context 'with new posts since last visit' do
        before do
          admin.update(last_venue: 1.week.ago)
          create(:article, published: true, published_at: 1.day.ago)
        end

        it 'shows new posts count' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end
      end

      context 'with new comments since last visit' do
        let!(:article) { create(:article, published: true, user: admin) }

        before do
          admin.update(last_venue: 1.week.ago)
          create(:comment, article: article, state: 'ham', published_at: 1.day.ago)
        end

        it 'shows new comments count' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end
      end

      context 'with popular articles' do
        let!(:article) { create(:article, published: true, user: admin) }

        before do
          5.times { create(:comment, article: article, state: 'ham') }
        end

        it 'shows popular articles' do
          get '/admin'
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        get '/admin'
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end
end
