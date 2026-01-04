# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Tags', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/tags' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/tags'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/tags'
        expect(response).to be_successful
      end

      it 'displays tag list' do
        FactoryBot.create(:tag, name: 'test-tag', display_name: 'Test Tag')
        get '/admin/tags'
        expect(response.body).to include('Test Tag')
      end

      it 'displays empty list when no tags exist' do
        get '/admin/tags'
        expect(response).to be_successful
      end

      it 'orders tags by display_name' do
        FactoryBot.create(:tag, name: 'zebra-tag', display_name: 'Zebra Tag')
        FactoryBot.create(:tag, name: 'alpha-tag', display_name: 'Alpha Tag')
        get '/admin/tags'
        expect(response.body.index('Alpha Tag')).to be < response.body.index('Zebra Tag')
      end

      it 'paginates tags' do
        15.times { |i| FactoryBot.create(:tag, name: "tag-#{i}", display_name: "Tag #{i}") }
        get '/admin/tags'
        expect(response).to be_successful
      end

      it 'displays multiple tags' do
        FactoryBot.create(:tag, name: 'first-tag', display_name: 'First Tag')
        FactoryBot.create(:tag, name: 'second-tag', display_name: 'Second Tag')
        get '/admin/tags'
        expect(response.body).to include('First Tag')
        expect(response.body).to include('Second Tag')
      end
    end
  end

  describe 'GET /admin/tags/edit/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        tag = FactoryBot.create(:tag)
        get "/admin/tags/edit/#{tag.id}"
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        tag = FactoryBot.create(:tag)
        get "/admin/tags/edit/#{tag.id}"
        expect(response).to be_successful
      end

      it 'displays edit form with tag data' do
        tag = FactoryBot.create(:tag, name: 'editable-tag', display_name: 'Editable Tag')
        get "/admin/tags/edit/#{tag.id}"
        expect(response.body).to include('Editable Tag')
      end

      it 'displays the tag display_name in the page heading' do
        tag = FactoryBot.create(:tag, name: 'my-tag-name', display_name: 'My Tag Name')
        get "/admin/tags/edit/#{tag.id}"
        expect(response.body).to include('Editing tag')
        expect(response.body).to include('My Tag Name')
      end
    end
  end

  describe 'POST /admin/tags/edit/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        tag = FactoryBot.create(:tag)
        post "/admin/tags/edit/#{tag.id}", params: { tag: { display_name: 'Updated' } }
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'updates the tag display_name' do
        tag = FactoryBot.create(:tag, display_name: 'Original Tag')
        post "/admin/tags/edit/#{tag.id}", params: {
          tag: {
            display_name: 'Updated Tag'
          }
        }
        expect(tag.reload.display_name).to eq('Updated Tag')
      end

      it 'updates the tag name based on display_name' do
        tag = FactoryBot.create(:tag, name: 'original-tag', display_name: 'Original Tag')
        post "/admin/tags/edit/#{tag.id}", params: {
          tag: {
            display_name: 'New Tag Name'
          }
        }
        expect(tag.reload.name).to eq('new-tag-name')
      end

      it 'redirects to index after update' do
        tag = FactoryBot.create(:tag)
        post "/admin/tags/edit/#{tag.id}", params: {
          tag: {
            display_name: 'Updated Display Name'
          }
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'sets flash notice on successful update' do
        tag = FactoryBot.create(:tag)
        post "/admin/tags/edit/#{tag.id}", params: {
          tag: {
            display_name: 'Flash Test Tag'
          }
        }
        expect(flash[:notice]).to include('successfully updated')
      end

      it 'creates a redirect for the old tag name' do
        tag = FactoryBot.create(:tag, name: 'old-name', display_name: 'Old Name')
        expect do
          post "/admin/tags/edit/#{tag.id}", params: {
            tag: {
              name: 'new-name',
              display_name: 'New Name'
            }
          }
        end.to change { Redirect.count }.by(1)
      end

      it 'creates redirect with correct from_path' do
        tag = FactoryBot.create(:tag, name: 'original-path', display_name: 'Original Path')
        post "/admin/tags/edit/#{tag.id}", params: {
          tag: {
            display_name: 'Changed Path'
          }
        }
        redirect = Redirect.last
        expect(redirect.from_path).to eq('/tag/original-path')
      end

      it 'updates tag with special characters in display_name' do
        tag = FactoryBot.create(:tag, display_name: 'Original')
        post "/admin/tags/edit/#{tag.id}", params: {
          tag: {
            display_name: 'Ruby & Rails'
          }
        }
        expect(tag.reload.display_name).to eq('Ruby & Rails')
      end
    end
  end

  describe 'GET /admin/tags/destroy/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        tag = FactoryBot.create(:tag)
        get "/admin/tags/destroy/#{tag.id}"
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'displays confirmation page' do
        tag = FactoryBot.create(:tag)
        get "/admin/tags/destroy/#{tag.id}"
        expect(response).to be_successful
      end

      it 'does not delete the tag on GET' do
        tag = FactoryBot.create(:tag)
        expect do
          get "/admin/tags/destroy/#{tag.id}"
        end.not_to(change { Tag.count })
      end

      it 'shows delete confirmation message' do
        tag = FactoryBot.create(:tag, display_name: 'Delete Me Tag')
        get "/admin/tags/destroy/#{tag.id}"
        expect(response.body).to include('Are you sure you want to delete')
      end

      it 'shows delete button on confirmation page' do
        tag = FactoryBot.create(:tag)
        get "/admin/tags/destroy/#{tag.id}"
        expect(response.body).to include('delete')
      end
    end
  end

  describe 'POST /admin/tags/destroy/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        tag = FactoryBot.create(:tag)
        post "/admin/tags/destroy/#{tag.id}"
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'deletes the tag' do
        tag = FactoryBot.create(:tag)
        expect do
          post "/admin/tags/destroy/#{tag.id}"
        end.to change { Tag.count }.by(-1)
      end

      it 'redirects to index after deletion' do
        tag = FactoryBot.create(:tag)
        post "/admin/tags/destroy/#{tag.id}"
        expect(response).to redirect_to(action: 'index')
      end

      it 'removes tag from articles when deleted' do
        tag = FactoryBot.create(:tag, name: 'deletable-tag', display_name: 'Deletable Tag')
        article = FactoryBot.create(:article, user: @admin)
        article.tags << tag
        post "/admin/tags/destroy/#{tag.id}"
        expect(article.reload.tags).not_to include(tag)
      end

      it 'deletes tag even with associated articles' do
        tag = FactoryBot.create(:tag)
        article = FactoryBot.create(:article, user: @admin)
        article.tags << tag
        expect do
          post "/admin/tags/destroy/#{tag.id}"
        end.to change { Tag.count }.by(-1)
      end
    end
  end

  describe 'Tags with articles' do
    before { login_admin }

    it 'displays tags with associated articles' do
      tag = FactoryBot.create(:tag, name: 'popular-tag', display_name: 'Popular Tag')
      article = FactoryBot.create(:article, user: @admin)
      article.tags << tag
      get '/admin/tags'
      expect(response).to be_successful
    end

    it 'displays tag with multiple articles' do
      tag = FactoryBot.create(:tag, name: 'multi-article-tag', display_name: 'Multi Article Tag')
      article1 = FactoryBot.create(:article, user: @admin, title: 'First Article')
      article2 = FactoryBot.create(:article, user: @admin, title: 'Second Article')
      article1.tags << tag
      article2.tags << tag
      get '/admin/tags'
      expect(response).to be_successful
      expect(response.body).to include('Multi Article Tag')
    end

    it 'allows editing tags with associated articles' do
      tag = FactoryBot.create(:tag, name: 'article-tag', display_name: 'Article Tag')
      article = FactoryBot.create(:article, user: @admin)
      article.tags << tag
      get "/admin/tags/edit/#{tag.id}"
      expect(response).to be_successful
    end
  end

  describe 'Pagination' do
    before { login_admin }

    it 'shows page 1 by default' do
      25.times { |i| FactoryBot.create(:tag, name: "paged-tag-#{i}", display_name: "Paged Tag #{i}") }
      get '/admin/tags'
      expect(response).to be_successful
    end

    it 'shows page 2 of tags' do
      25.times { |i| FactoryBot.create(:tag, name: "bulk-tag-#{i}", display_name: "Bulk Tag #{i}") }
      get '/admin/tags', params: { page: 2 }
      expect(response).to be_successful
    end

    it 'handles empty page gracefully' do
      get '/admin/tags', params: { page: 100 }
      expect(response).to be_successful
    end

    it 'handles invalid page parameter' do
      get '/admin/tags', params: { page: 'invalid' }
      expect(response).to be_successful
    end
  end

  describe 'Edge cases' do
    before { login_admin }

    it 'handles tags with unicode characters' do
      FactoryBot.create(:tag, display_name: 'Ruby on Rails')
      get '/admin/tags'
      expect(response).to be_successful
      expect(response.body).to include('Ruby on Rails')
    end

    it 'handles tags with very long names' do
      long_name = 'A' * 100
      FactoryBot.create(:tag, display_name: long_name)
      get '/admin/tags'
      expect(response).to be_successful
    end

    it 'handles tag with spaces in display_name' do
      tag = FactoryBot.create(:tag, display_name: 'Multiple Word Tag Name')
      get "/admin/tags/edit/#{tag.id}"
      expect(response).to be_successful
      expect(response.body).to include('Multiple Word Tag Name')
    end
  end
end
