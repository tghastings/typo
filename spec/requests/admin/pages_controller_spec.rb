# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Pages', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/pages' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/pages'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/pages'
        expect(response).to be_successful
      end

      it 'displays page list' do
        page = FactoryBot.create(:page, user: @admin)
        get '/admin/pages'
        expect(response.body).to include(page.title)
      end
    end
  end

  describe 'GET /admin/pages/new' do
    before { login_admin }

    it 'returns successful response' do
      get '/admin/pages/new'
      expect(response).to be_successful
    end

    it 'displays new page form' do
      get '/admin/pages/new'
      expect(response.body).to include('Title')
    end
  end

  describe 'POST /admin/pages/new' do
    before { login_admin }

    it 'creates a new page' do
      expect {
        post '/admin/pages/new', params: {
          page: {
            title: 'Test Page',
            body: 'Test page content',
            name: 'test-page'
          }
        }
      }.to change { Page.count }.by(1)
    end

    it 'redirects to index after creation' do
      post '/admin/pages/new', params: {
        page: {
          title: 'Test Page',
          body: 'Test page content',
          name: 'test-page-2'
        }
      }
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets the correct user on the page' do
      post '/admin/pages/new', params: {
        page: {
          title: 'User Page',
          body: 'Page with user',
          name: 'user-page'
        }
      }
      expect(Page.last.user).to eq(@admin)
    end
  end

  describe 'GET /admin/pages/edit/:id' do
    before { login_admin }

    it 'returns successful response' do
      page = FactoryBot.create(:page, user: @admin)
      get "/admin/pages/edit/#{page.id}"
      expect(response).to be_successful
    end

    it 'displays edit form with page data' do
      page = FactoryBot.create(:page, user: @admin, title: 'Editable Page')
      get "/admin/pages/edit/#{page.id}"
      expect(response.body).to include('Editable Page')
    end
  end

  describe 'POST /admin/pages/edit/:id' do
    before { login_admin }

    it 'updates the page' do
      page = FactoryBot.create(:page, user: @admin, title: 'Original Page Title')
      post "/admin/pages/edit/#{page.id}", params: {
        page: {
          title: 'Updated Page Title',
          body: page.body
        }
      }
      expect(page.reload.title).to eq('Updated Page Title')
    end

    it 'redirects to index after update' do
      page = FactoryBot.create(:page, user: @admin)
      post "/admin/pages/edit/#{page.id}", params: {
        page: {
          title: 'Updated',
          body: 'Updated body'
        }
      }
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe 'GET /admin/pages/destroy/:id' do
    before { login_admin }

    it 'displays confirmation page' do
      page = FactoryBot.create(:page, user: @admin)
      get "/admin/pages/destroy/#{page.id}"
      expect(response).to be_successful
    end

    it 'does not delete the page on GET' do
      page = FactoryBot.create(:page, user: @admin)
      expect {
        get "/admin/pages/destroy/#{page.id}"
      }.not_to change { Page.count }
    end
  end

  describe 'POST /admin/pages/destroy/:id' do
    before { login_admin }

    it 'deletes the page' do
      page = FactoryBot.create(:page, user: @admin)
      expect {
        post "/admin/pages/destroy/#{page.id}"
      }.to change { Page.count }.by(-1)
    end

    it 'redirects to index after deletion' do
      page = FactoryBot.create(:page, user: @admin)
      post "/admin/pages/destroy/#{page.id}"
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe 'Search functionality' do
    before { login_admin }

    it 'filters pages by search term' do
      FactoryBot.create(:page, user: @admin, body: 'unique_page_content')
      FactoryBot.create(:page, user: @admin, body: 'different content', name: 'different')
      get '/admin/pages', params: { search: { searchstring: 'unique_page_content' } }
      expect(response).to be_successful
    end

    it 'filters pages by published status' do
      FactoryBot.create(:page, user: @admin, published: true)
      get '/admin/pages', params: { search: { published: '1' } }
      expect(response).to be_successful
    end
  end

  describe 'Editor switching' do
    before { login_admin }

    it 'switches to simple editor' do
      get '/admin/pages/insert_editor', params: { editor: 'simple' }
      expect(response).to be_successful
    end

    it 'switches to visual editor' do
      get '/admin/pages/insert_editor', params: { editor: 'visual' }
      expect(response).to be_successful
    end
  end
end
