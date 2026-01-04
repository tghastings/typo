# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::PostTypes', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/post_types' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/post_types'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'redirects to new action' do
        get '/admin/post_types'
        expect(response).to redirect_to(action: 'new')
      end
    end
  end

  describe 'GET /admin/post_types/new' do
    context 'when logged in as admin' do
      before { login_admin }

      it 'renders the new form' do
        get '/admin/post_types/new'
        expect(response).to be_successful
      end

      it 'lists existing post types' do
        FactoryBot.create(:post_type, name: 'article')
        get '/admin/post_types/new'
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /admin/post_types/new' do
    before { login_admin }

    context 'with valid parameters' do
      it 'creates a new post type' do
        expect do
          post '/admin/post_types/new', params: {
            post_type: { name: 'review', description: 'Product reviews' }
          }
        end.to change(PostType, :count).by(1)
      end

      it 'redirects to index after save' do
        post '/admin/post_types/new', params: {
          post_type: { name: 'video', description: 'Video posts' }
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'sets success flash message' do
        post '/admin/post_types/new', params: {
          post_type: { name: 'podcast', description: 'Podcast episodes' }
        }
        follow_redirect!
        expect(flash[:notice]).to include('successfully saved')
      end
    end
  end

  describe 'GET /admin/post_types/edit/:id' do
    before { login_admin }

    it 'renders the edit form' do
      post_type = FactoryBot.create(:post_type)
      get "/admin/post_types/edit/#{post_type.id}"
      expect(response).to be_successful
    end
  end

  describe 'POST /admin/post_types/edit/:id' do
    before { login_admin }

    it 'updates the post type' do
      post_type = FactoryBot.create(:post_type, name: 'old_name')
      post "/admin/post_types/edit/#{post_type.id}", params: {
        post_type: { name: 'new_name', description: 'Updated description' }
      }
      expect(response).to redirect_to(action: 'index')
      expect(post_type.reload.name).to eq('new_name')
    end
  end

  describe 'GET /admin/post_types/destroy/:id' do
    before { login_admin }

    it 'renders the destroy confirmation' do
      post_type = FactoryBot.create(:post_type)
      get "/admin/post_types/destroy/#{post_type.id}"
      expect(response).to be_successful
    end

    it 'does not delete on GET request' do
      post_type = FactoryBot.create(:post_type)
      expect do
        get "/admin/post_types/destroy/#{post_type.id}"
      end.not_to change(PostType, :count)
    end
  end

  describe 'POST /admin/post_types/destroy/:id' do
    before { login_admin }

    it 'deletes the post type' do
      post_type = FactoryBot.create(:post_type)
      expect do
        post "/admin/post_types/destroy/#{post_type.id}"
      end.to change(PostType, :count).by(-1)
    end

    it 'redirects to index' do
      post_type = FactoryBot.create(:post_type)
      post "/admin/post_types/destroy/#{post_type.id}"
      expect(response).to redirect_to(action: 'index')
    end

    it 'resets articles using this post type' do
      post_type = FactoryBot.create(:post_type, name: 'custom')
      article = FactoryBot.create(:article, post_type: post_type.permalink)
      post "/admin/post_types/destroy/#{post_type.id}"
      expect(article.reload.post_type).to eq('read')
    end
  end
end
