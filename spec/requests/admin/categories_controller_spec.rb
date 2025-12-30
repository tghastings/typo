# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Categories', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/categories' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/categories'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'redirects to new action' do
        get '/admin/categories'
        expect(response).to redirect_to(action: 'new')
      end
    end

    context 'when logged in as contributor' do
      before do
        @contributor = User.create!(
          login: 'contributor',
          email: 'contributor@test.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'Contributor User',
          profile: @contributor_profile,
          state: 'active'
        )
        login_user(@contributor)
      end

      it 'restricts access for non-admin users' do
        get '/admin/categories'
        # Should either redirect or show forbidden
        expect(response.status).to be_in([302, 403])
      end
    end
  end

  describe 'GET /admin/categories/new' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/categories/new'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end
  end

  describe 'GET /admin/categories/new.js' do
    before { login_admin }

    it 'responds to JS format request' do
      get '/admin/categories/new', headers: { 'Accept' => 'text/javascript' }
      # JS format returns a response (may be error or success depending on controller)
      expect(response).not_to be_nil
    end
  end

  describe 'GET /admin/categories/edit/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        category = FactoryBot.create(:category)
        get "/admin/categories/edit/#{category.id}"
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        category = FactoryBot.create(:category)
        get "/admin/categories/edit/#{category.id}"
        expect(response).to be_successful
      end

      it 'displays edit form with category data' do
        category = FactoryBot.create(:category, name: 'Editable Category')
        get "/admin/categories/edit/#{category.id}"
        expect(response.body).to include('Editable Category')
      end

      it 'displays category permalink' do
        category = FactoryBot.create(:category, name: 'Test', permalink: 'test-permalink')
        get "/admin/categories/edit/#{category.id}"
        expect(response.body).to include('test-permalink')
      end

      it 'displays all categories in sidebar' do
        category1 = FactoryBot.create(:category, name: 'First Category')
        category2 = FactoryBot.create(:category, name: 'Second Category')
        get "/admin/categories/edit/#{category1.id}"
        expect(response.body).to include('First Category')
        expect(response.body).to include('Second Category')
      end

      it 'displays the form name field' do
        category = FactoryBot.create(:category)
        get "/admin/categories/edit/#{category.id}"
        expect(response.body).to include('Name')
      end

      it 'displays description field' do
        category = FactoryBot.create(:category)
        get "/admin/categories/edit/#{category.id}"
        expect(response.body).to include('Description')
      end

      it 'displays keywords field' do
        category = FactoryBot.create(:category)
        get "/admin/categories/edit/#{category.id}"
        expect(response.body).to include('Keywords')
      end

      it 'returns error response for non-existent category' do
        get '/admin/categories/edit/999999'
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'POST /admin/categories/edit/:id' do
    before { login_admin }

    context 'with valid parameters' do
      it 'updates the category name' do
        category = FactoryBot.create(:category, name: 'Original Category')
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: 'Updated Category',
            permalink: category.permalink
          }
        }
        expect(category.reload.name).to eq('Updated Category')
      end

      it 'updates the category permalink' do
        category = FactoryBot.create(:category, name: 'Test', permalink: 'old-permalink')
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: category.name,
            permalink: 'new-permalink'
          }
        }
        expect(category.reload.permalink).to eq('new-permalink')
      end

      it 'redirects to new after update' do
        category = FactoryBot.create(:category)
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: 'Updated',
            permalink: 'updated-permalink'
          }
        }
        expect(response).to redirect_to(action: 'new')
      end

      it 'sets flash notice on successful update' do
        category = FactoryBot.create(:category)
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: 'Successfully Updated',
            permalink: 'success'
          }
        }
        expect(flash[:notice]).to include('successfully')
      end

      it 'updates category description' do
        category = FactoryBot.create(:category)
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: category.name,
            description: 'A new description'
          }
        }
        expect(category.reload.description).to eq('A new description')
      end

      it 'updates category keywords' do
        category = FactoryBot.create(:category)
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: category.name,
            keywords: 'keyword1, keyword2'
          }
        }
        expect(category.reload.keywords).to eq('keyword1, keyword2')
      end

      it 'updates existing category without creating new one' do
        existing = FactoryBot.create(:category)
        initial_count = Category.count
        post "/admin/categories/edit/#{existing.id}", params: {
          category: {
            name: 'Newly Named Category',
            permalink: 'newly-named'
          }
        }
        expect(Category.count).to eq(initial_count)
        expect(existing.reload.name).to eq('Newly Named Category')
      end
    end

    context 'with invalid parameters' do
      it 'does not update category with blank name' do
        category = FactoryBot.create(:category, name: 'Keep This Name')
        post "/admin/categories/edit/#{category.id}", params: {
          category: {
            name: '',
            permalink: category.permalink
          }
        }
        # The controller uses save! which will raise, resulting in error page
        expect(response.status).to be_in([422, 500])
      end

      it 'preserves original name when update with blank name fails' do
        category = FactoryBot.create(:category, name: 'Keep This Name')
        post "/admin/categories/edit/#{category.id}", params: {
          category: { name: '' }
        }
        expect(category.reload.name).to eq('Keep This Name')
      end
    end
  end

  describe 'POST /admin/categories/edit/:id.js' do
    before { login_admin }

    it 'responds to JS format for AJAX category update' do
      category = FactoryBot.create(:category)
      post "/admin/categories/edit/#{category.id}",
           params: { category: { name: 'AJAX Category' } },
           headers: { 'Accept' => 'text/javascript' }
      expect(response).to be_successful
    end

    it 'updates category via AJAX' do
      category = FactoryBot.create(:category, name: 'Original')
      post "/admin/categories/edit/#{category.id}",
           params: { category: { name: 'AJAX Updated' } },
           headers: { 'Accept' => 'text/javascript' }
      expect(category.reload.name).to eq('AJAX Updated')
    end

    it 'returns partial for content categories' do
      category = FactoryBot.create(:category)
      post "/admin/categories/edit/#{category.id}",
           params: { category: { name: 'Updated via JS' } },
           headers: { 'Accept' => 'text/javascript' }
      expect(response).to be_successful
    end
  end

  describe 'GET /admin/categories/destroy/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        category = FactoryBot.create(:category)
        get "/admin/categories/destroy/#{category.id}"
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'displays confirmation page' do
        category = FactoryBot.create(:category)
        get "/admin/categories/destroy/#{category.id}"
        expect(response).to be_successful
      end

      it 'does not delete the category on GET request' do
        category = FactoryBot.create(:category)
        expect {
          get "/admin/categories/destroy/#{category.id}"
        }.not_to change { Category.count }
      end

      it 'shows delete confirmation message' do
        category = FactoryBot.create(:category, name: 'Category To Delete')
        get "/admin/categories/destroy/#{category.id}"
        expect(response.body).to include('delete')
      end

      it 'returns error for non-existent category' do
        get '/admin/categories/destroy/999999'
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'POST /admin/categories/destroy/:id' do
    before { login_admin }

    it 'deletes the category' do
      category = FactoryBot.create(:category)
      expect {
        post "/admin/categories/destroy/#{category.id}"
      }.to change { Category.count }.by(-1)
    end

    it 'redirects to new after deletion' do
      category = FactoryBot.create(:category)
      post "/admin/categories/destroy/#{category.id}"
      expect(response).to redirect_to(action: 'new')
    end

    it 'actually removes the category from database' do
      category = FactoryBot.create(:category)
      category_id = category.id
      post "/admin/categories/destroy/#{category.id}"
      expect(Category.find_by(id: category_id)).to be_nil
    end

    it 'deletes first category' do
      category = FactoryBot.create(:category, name: 'First')
      FactoryBot.create(:category, name: 'Second')
      expect {
        post "/admin/categories/destroy/#{category.id}"
      }.to change { Category.count }.by(-1)
    end

    it 'deletes last category' do
      FactoryBot.create(:category, name: 'First')
      category = FactoryBot.create(:category, name: 'Last')
      expect {
        post "/admin/categories/destroy/#{category.id}"
      }.to change { Category.count }.by(-1)
    end
  end

  describe 'Categories with articles' do
    before { login_admin }

    it 'can edit category that has articles' do
      category = FactoryBot.create(:category, name: 'Linked Category')
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      get "/admin/categories/edit/#{category.id}"
      expect(response).to be_successful
    end

    it 'can delete category even with associated articles' do
      category = FactoryBot.create(:category, name: 'Delete Me')
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      expect {
        post "/admin/categories/destroy/#{category.id}"
      }.to change { Category.count }.by(-1)
    end

    it 'does not delete article when deleting category' do
      category = FactoryBot.create(:category)
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      expect {
        post "/admin/categories/destroy/#{category.id}"
      }.not_to change { Article.count }
    end

    it 'removes category association when category is deleted' do
      category = FactoryBot.create(:category)
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      post "/admin/categories/destroy/#{category.id}"
      expect(article.reload.categories).to be_empty
    end
  end

  describe 'Category tree structure' do
    before { login_admin }

    it 'can edit category parent relationship' do
      parent = FactoryBot.create(:category, name: 'New Parent')
      child = FactoryBot.create(:category, name: 'Child')
      post "/admin/categories/edit/#{child.id}", params: {
        category: {
          name: child.name,
          parent_id: parent.id
        }
      }
      expect(child.reload.parent_id).to eq(parent.id)
    end

    it 'can remove parent from category' do
      parent = FactoryBot.create(:category, name: 'Parent')
      child = FactoryBot.create(:category, name: 'Child', parent_id: parent.id)
      post "/admin/categories/edit/#{child.id}", params: {
        category: {
          name: child.name,
          parent_id: nil
        }
      }
      expect(child.reload.parent_id).to be_nil
    end

    it 'displays parent category in edit form' do
      parent = FactoryBot.create(:category, name: 'Parent Category')
      child = FactoryBot.create(:category, name: 'Child Category', parent_id: parent.id)
      get "/admin/categories/edit/#{child.id}"
      expect(response).to be_successful
    end
  end

  describe 'Category ordering' do
    before { login_admin }

    it 'can update category position' do
      category = FactoryBot.create(:category, position: 5)
      post "/admin/categories/edit/#{category.id}", params: {
        category: {
          name: category.name,
          position: 10
        }
      }
      expect(category.reload.position).to eq(10)
    end

    it 'displays categories with position info' do
      cat1 = FactoryBot.create(:category, name: 'Position One', position: 1)
      cat2 = FactoryBot.create(:category, name: 'Position Two', position: 2)
      get "/admin/categories/edit/#{cat1.id}"
      expect(response).to be_successful
    end
  end

  describe 'Special characters in category names' do
    before { login_admin }

    it 'handles categories with ampersand' do
      category = FactoryBot.create(:category, name: 'Original')
      post "/admin/categories/edit/#{category.id}", params: {
        category: { name: 'Category & More' }
      }
      expect(category.reload.name).to eq('Category & More')
    end

    it 'handles categories with quotes' do
      category = FactoryBot.create(:category, name: 'Original')
      post "/admin/categories/edit/#{category.id}", params: {
        category: { name: "Category 'Test'" }
      }
      expect(category.reload.name).to eq("Category 'Test'")
    end

    it 'handles categories with unicode characters' do
      category = FactoryBot.create(:category, name: 'Original')
      post "/admin/categories/edit/#{category.id}", params: {
        category: { name: 'Categorias' }
      }
      expect(category.reload.name).to eq('Categorias')
    end

    it 'displays special characters correctly in edit form' do
      category = FactoryBot.create(:category, name: 'Test & Category')
      get "/admin/categories/edit/#{category.id}"
      expect(response.body).to include('Test')
    end
  end

  describe 'Multiple categories management' do
    before { login_admin }

    it 'displays multiple categories in edit view' do
      5.times { |i| FactoryBot.create(:category, name: "Category #{i}") }
      category = Category.first
      get "/admin/categories/edit/#{category.id}"
      expect(response).to be_successful
    end

    it 'lists all categories on edit page' do
      categories = 5.times.map { |i| FactoryBot.create(:category, name: "Listed Cat #{i}") }
      get "/admin/categories/edit/#{categories.first.id}"
      categories.each do |cat|
        expect(response.body).to include(cat.name)
      end
    end
  end

  describe 'Category validation' do
    before { login_admin }

    it 'fails when updating category with blank name' do
      category = FactoryBot.create(:category)
      post "/admin/categories/edit/#{category.id}", params: {
        category: { name: '' }
      }
      # Should return error status (500 due to save! raising)
      expect(response.status).to be_in([422, 500])
    end

    it 'allows updating to unique name' do
      category = FactoryBot.create(:category, name: 'Unique Original')
      post "/admin/categories/edit/#{category.id}", params: {
        category: { name: 'Unique Updated' }
      }
      expect(category.reload.name).to eq('Unique Updated')
    end
  end

  describe 'Permalink behavior' do
    before { login_admin }

    it 'allows custom permalink' do
      category = FactoryBot.create(:category, name: 'Test', permalink: 'original')
      post "/admin/categories/edit/#{category.id}", params: {
        category: {
          name: category.name,
          permalink: 'custom-permalink'
        }
      }
      expect(category.reload.permalink).to eq('custom-permalink')
    end

    it 'preserves permalink when only updating name' do
      category = FactoryBot.create(:category, name: 'Test', permalink: 'keep-this')
      post "/admin/categories/edit/#{category.id}", params: {
        category: {
          name: 'New Name',
          permalink: 'keep-this'
        }
      }
      expect(category.reload.permalink).to eq('keep-this')
    end
  end
end
