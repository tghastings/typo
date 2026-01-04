# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Redirects', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/redirects' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/redirects'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'redirects to new action' do
        get '/admin/redirects'
        expect(response).to redirect_to(action: 'new')
      end
    end
  end

  describe 'GET /admin/redirects/new' do
    context 'when logged in as admin' do
      before { login_admin }

      it 'renders the new form' do
        get '/admin/redirects/new'
        expect(response).to be_successful
      end

      it 'lists existing redirects' do
        FactoryBot.create(:redirect, from_path: 'old-path', to_path: '/new-path')
        get '/admin/redirects/new'
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /admin/redirects/new' do
    before { login_admin }

    context 'with valid parameters' do
      it 'creates a new redirect' do
        expect do
          post '/admin/redirects/new', params: {
            redirect: { from_path: 'old-url', to_path: '/new-url' }
          }
        end.to change(Redirect, :count).by(1)
      end

      it 'redirects to index after save' do
        post '/admin/redirects/new', params: {
          redirect: { from_path: 'another-old', to_path: '/another-new' }
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'sets success flash message' do
        post '/admin/redirects/new', params: {
          redirect: { from_path: 'test-old', to_path: '/test-new' }
        }
        follow_redirect!
        expect(flash[:notice]).to include('successfully saved')
      end

      it 'auto-generates from_path when empty' do
        post '/admin/redirects/new', params: {
          redirect: { from_path: '', to_path: 'http://example.com/long-url' }
        }
        redirect = Redirect.last
        expect(redirect.from_path).not_to be_empty
      end
    end
  end

  describe 'GET /admin/redirects/edit/:id' do
    before { login_admin }

    it 'renders the edit form' do
      redirect = FactoryBot.create(:redirect)
      get "/admin/redirects/edit/#{redirect.id}"
      expect(response).to be_successful
    end
  end

  describe 'POST /admin/redirects/edit/:id' do
    before { login_admin }

    it 'updates the redirect' do
      redirect = FactoryBot.create(:redirect, to_path: '/old-destination')
      post "/admin/redirects/edit/#{redirect.id}", params: {
        redirect: { to_path: '/new-destination' }
      }
      expect(response).to redirect_to(action: 'index')
      expect(redirect.reload.to_path).to eq('/new-destination')
    end
  end

  describe 'GET /admin/redirects/destroy/:id' do
    before { login_admin }

    it 'renders the destroy confirmation' do
      redirect = FactoryBot.create(:redirect)
      get "/admin/redirects/destroy/#{redirect.id}"
      expect(response).to be_successful
    end

    it 'does not delete on GET request' do
      redirect = FactoryBot.create(:redirect)
      expect do
        get "/admin/redirects/destroy/#{redirect.id}"
      end.not_to change(Redirect, :count)
    end
  end

  describe 'POST /admin/redirects/destroy/:id' do
    before { login_admin }

    it 'deletes the redirect' do
      redirect = FactoryBot.create(:redirect)
      expect do
        post "/admin/redirects/destroy/#{redirect.id}"
      end.to change(Redirect, :count).by(-1)
    end

    it 'redirects to index' do
      redirect = FactoryBot.create(:redirect)
      post "/admin/redirects/destroy/#{redirect.id}"
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets success flash message' do
      redirect = FactoryBot.create(:redirect)
      post "/admin/redirects/destroy/#{redirect.id}"
      follow_redirect!
      expect(flash[:notice]).to include('successfully deleted')
    end
  end
end
