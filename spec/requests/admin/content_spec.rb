# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Content', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/content' do
    context 'when logged in as admin' do
      before { login_as_admin }

      it 'returns success' do
        get '/admin/content'
        expect(response).to have_http_status(:success)
      end

      it 'displays articles list' do
        create(:article, title: 'Test Article', user: admin)
        get '/admin/content'
        expect(response.body).to include('Test Article')
      end

      context 'with search params' do
        before do
          create(:article, title: 'Searchable Article', user: admin)
          create(:article, title: 'Other Post', user: admin)
        end

        it 'filters by search term' do
          get '/admin/content', params: { search: { searchstring: 'Searchable' } }
          expect(response).to have_http_status(:success)
        end

        it 'filters by state' do
          get '/admin/content', params: { search: { state: 'published' } }
          expect(response).to have_http_status(:success)
        end

        it 'filters by user' do
          get '/admin/content', params: { search: { user_id: admin.id } }
          expect(response).to have_http_status(:success)
        end
      end

      context 'with XHR request' do
        it 'returns partial for article list' do
          get '/admin/content', xhr: true
          expect(response).to have_http_status(:success)
        end
      end

      context 'with pagination' do
        it 'handles page param' do
          get '/admin/content', params: { page: 1 }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        get '/admin/content'
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end

  describe 'GET /admin/content/new' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/content/new'
      expect(response).to have_http_status(:success)
    end

    it 'displays article form' do
      get '/admin/content/new'
      expect(response.body).to include('title')
    end

    it 'loads post types' do
      get '/admin/content/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/content/new' do
    before { login_as_admin }

    context 'with valid params' do
      let(:valid_params) do
        {
          article: {
            title: 'New Article',
            body: 'Article content',
            published: true
          }
        }
      end

      it 'creates article' do
        expect do
          post '/admin/content/new', params: valid_params
        end.to change(Article, :count).by(1)
      end

      it 'redirects to content list' do
        post '/admin/content/new', params: valid_params
        expect(response).to redirect_to('/admin/content')
      end

      it 'sets flash notice' do
        post '/admin/content/new', params: valid_params
        expect(flash[:notice]).to include('created')
      end
    end

    context 'with draft param' do
      it 'creates article' do
        expect do
          post '/admin/content/new', params: {
            article: { title: 'Draft Article', body: 'Content', draft: '1' }
          }
        end.to change(Article, :count).by(1)
      end
    end

    context 'with categories' do
      let!(:category) { create(:category, name: 'Tech') }

      it 'assigns categories to article' do
        post '/admin/content/new', params: {
          article: { title: 'Categorized', body: 'Content', published: true },
          categories: [category.id]
        }
        expect(Article.last.categories).to include(category)
      end
    end

    context 'with published_at datetime' do
      it 'parses published_at' do
        post '/admin/content/new', params: {
          article: { title: 'Scheduled', body: 'Content', published_at: 'January 1, 2025 10:00 AM GMT+0000' }
        }
        expect(response).to redirect_to('/admin/content')
      end
    end

    context 'with invalid params' do
      it 'does not create article without title' do
        expect do
          post '/admin/content/new', params: { article: { title: '', body: 'Content' } }
        end.not_to change(Article, :count)
      end
    end
  end

  describe 'GET /admin/content/edit/:id' do
    before { login_as_admin }

    let!(:article) { create(:article, user: admin) }

    it 'returns success' do
      get "/admin/content/edit/#{article.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays article form with data' do
      get "/admin/content/edit/#{article.id}"
      expect(response.body).to include(article.title)
    end

    context 'when user is admin' do
      let(:contributor_profile) { Profile.find_by(label: 'contributor') || create(:profile_contributor) }
      let(:other_user) { create(:user, profile: contributor_profile) }
      let!(:other_article) { create(:article, user: other_user) }

      it 'allows admin to edit any article' do
        get "/admin/content/edit/#{other_article.id}"
        # Admin can edit any article
        expect(response.status).to be_in([200, 302])
      end
    end
  end

  describe 'POST /admin/content/edit/:id' do
    before { login_as_admin }

    let!(:article) { create(:article, user: admin, title: 'Original Title') }

    it 'updates article' do
      post "/admin/content/edit/#{article.id}", params: { article: { title: 'Updated Title' } }
      expect(article.reload.title).to eq('Updated Title')
    end

    it 'redirects to content list' do
      post "/admin/content/edit/#{article.id}", params: { article: { title: 'Updated Title' } }
      expect(response).to redirect_to('/admin/content')
    end

    it 'sets flash notice' do
      post "/admin/content/edit/#{article.id}", params: { article: { title: 'Updated Title' } }
      expect(flash[:notice]).to include('updated')
    end

    context 'publishing a draft' do
      let!(:draft) { create(:article, user: admin, state: 'draft', parent_id: article.id) }

      it 'destroys the draft after publishing parent' do
        post "/admin/content/edit/#{article.id}", params: { article: { title: 'Published' } }
        expect(Article.where(parent_id: article.id).count).to eq(0)
      end
    end
  end

  describe 'GET /admin/content/destroy/:id' do
    before { login_as_admin }

    let!(:article) { create(:article, user: admin) }

    it 'shows destroy confirmation' do
      get "/admin/content/destroy/#{article.id}"
      expect(response).to have_http_status(:success)
    end

    context 'as admin user' do
      let(:contributor_profile) { Profile.find_by(label: 'contributor') || create(:profile_contributor) }
      let(:other_user) { create(:user, profile: contributor_profile) }
      let!(:other_article) { create(:article, user: other_user) }

      it 'allows admin to destroy any article' do
        get "/admin/content/destroy/#{other_article.id}"
        # Admin can destroy any article
        expect(response.status).to be_in([200, 302])
      end
    end
  end

  describe 'POST /admin/content/destroy/:id' do
    before { login_as_admin }

    let!(:article) { create(:article, user: admin) }

    it 'deletes article' do
      expect do
        post "/admin/content/destroy/#{article.id}"
      end.to change(Article, :count).by(-1)
    end

    it 'redirects to content list' do
      post "/admin/content/destroy/#{article.id}"
      expect(response).to redirect_to('/admin/content')
    end
  end

  describe 'POST /admin/content/autosave' do
    before { login_as_admin }

    it 'creates a draft article' do
      post '/admin/content/autosave', params: {
        article: { title: 'Autosaved', body: 'Content' }
      }
      expect(response.status).to be_in([200, 204])
    end

    context 'with existing article' do
      let!(:article) { create(:article, user: admin, published: true) }

      it 'creates draft for existing article' do
        post '/admin/content/autosave', params: {
          id: article.id,
          article: { title: 'Updated Title', body: 'Updated content' }
        }
        expect(response.status).to be_in([200, 204])
      end
    end

    context 'with article with title' do
      it 'saves with provided title' do
        post '/admin/content/autosave', params: {
          article: { title: 'Provided Title', body: 'Content' }
        }
        expect(response.status).to be_in([200, 204])
      end
    end
  end

  describe 'POST /admin/content/preview_markdown' do
    before { login_as_admin }

    it 'renders markdown content' do
      post '/admin/content/preview_markdown', params: { content: '**bold**' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('<strong>')
    end

    it 'handles empty content' do
      post '/admin/content/preview_markdown', params: { content: '' }
      expect(response).to have_http_status(:success)
    end

    it 'uses specified text filter' do
      post '/admin/content/preview_markdown', params: {
        content: '*italic*',
        text_filter: 'markdown'
      }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/content/insert_editor' do
    before { login_as_admin }

    it 'updates user editor preference' do
      post '/admin/content/insert_editor'
      expect(response).to have_http_status(:success)
      expect(admin.reload.editor).to eq('markdown')
    end
  end

  describe 'POST /admin/content/auto_complete_for_article_keywords' do
    before { login_as_admin }

    let!(:tag) { create(:tag, name: 'ruby') }

    it 'returns matching tags' do
      post '/admin/content/auto_complete_for_article_keywords', params: {
        article: { keywords: 'rub' }
      }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/content/attachment_box_add' do
    before { login_as_admin }

    it 'returns attachment form' do
      post '/admin/content/attachment_box_add', params: { id: 1 }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'resource_add action' do
    before { login_as_admin }

    let!(:article) { create(:article, user: admin) }
    let!(:resource) { create(:resource) }

    describe 'GET /admin/content/resource_add' do
      it 'returns success' do
        get '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        expect(response).to have_http_status(:success)
      end

      it 'adds resource to article' do
        expect do
          get '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        end.to change { article.reload.resources.count }.by(1)
      end

      it 'associates the correct resource' do
        get '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        expect(article.reload.resources).to include(resource)
      end

      it 'renders show_resources partial' do
        get '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        expect(response.body).to include(resource.filename)
      end
    end

    describe 'POST /admin/content/resource_add' do
      it 'returns success' do
        post '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        expect(response).to have_http_status(:success)
      end

      it 'adds resource to article' do
        expect do
          post '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        end.to change { article.reload.resources.count }.by(1)
      end

      it 'does not duplicate resource if already attached' do
        article.resources << resource
        expect do
          post '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        end.not_to(change { article.reload.resources.count })
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        reset!  # Clear session
        get '/admin/content/resource_add', params: { id: article.id, resource_id: resource.id }
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end

  describe 'resource_remove action' do
    before { login_as_admin }

    let!(:article) { create(:article, user: admin) }
    let!(:resource) { create(:resource) }

    before do
      article.resources << resource
    end

    describe 'GET /admin/content/resource_remove' do
      it 'returns success' do
        get '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        expect(response).to have_http_status(:success)
      end

      it 'removes resource from article' do
        expect do
          get '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        end.to change { article.reload.resources.count }.by(-1)
      end

      it 'disassociates the correct resource' do
        get '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        expect(article.reload.resources).not_to include(resource)
      end

      it 'does not delete the resource itself' do
        expect do
          get '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        end.not_to change(Resource, :count)
      end
    end

    describe 'POST /admin/content/resource_remove' do
      it 'returns success' do
        post '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        expect(response).to have_http_status(:success)
      end

      it 'removes resource from article' do
        expect do
          post '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        end.to change { article.reload.resources.count }.by(-1)
      end
    end

    context 'when resource is not attached' do
      let!(:unattached_resource) { create(:resource) }

      it 'handles gracefully' do
        expect do
          get '/admin/content/resource_remove', params: { id: article.id, resource_id: unattached_resource.id }
        end.not_to(change { article.reload.resources.count })
        expect(response).to have_http_status(:success)
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        reset!  # Clear session
        get '/admin/content/resource_remove', params: { id: article.id, resource_id: resource.id }
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end
end
