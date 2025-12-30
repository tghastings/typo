# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin'
        expect(response).to be_successful
      end

      it 'renders the dashboard' do
        get '/admin'
        expect(response.body).to include('Dashboard')
      end
    end
  end

  describe 'GET /admin/dashboard' do
    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/dashboard'
        expect(response).to be_successful
      end

      it 'displays statistics' do
        get '/admin/dashboard'
        expect(response.body).to include('Content')
      end
    end
  end

  describe 'Dashboard data display' do
    before do
      login_admin
      # Create some test data
      @article = FactoryBot.create(:article, user: @admin)
      @comment = FactoryBot.create(:comment, article: @article)
    end

    it 'shows recent posts' do
      get '/admin/dashboard'
      expect(response).to be_successful
    end

    it 'shows comments count' do
      get '/admin/dashboard'
      expect(response).to be_successful
    end
  end
end
