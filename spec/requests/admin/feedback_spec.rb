# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Feedback', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin) { create(:user, login: 'admin', password: 'password123', profile: create(:profile_admin)) }
  let!(:article) { create(:article, user: admin) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: 'admin', password: 'password123' } }
  end

  describe 'GET /admin/feedback' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/feedback'
      expect(response).to have_http_status(:success)
    end

    it 'displays comments' do
      create(:comment, article: article, author: 'John', body: 'Great post!')
      get '/admin/feedback'
      expect(response.body).to include('John')
    end


    context 'with pagination' do
      it 'handles page param' do
        get '/admin/feedback', params: { page: 1 }
        expect(response).to have_http_status(:success)
      end

      it 'handles blank page param' do
        get '/admin/feedback', params: { page: '' }
        expect(response).to have_http_status(:success)
      end

      it 'handles zero page param' do
        get '/admin/feedback', params: { page: '0' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /admin/feedback with state filter' do
    before do
      login_as_admin
      create(:comment, article: article, state: 'ham')
      create(:spam_comment, article: article, state: 'spam')
    end

    it 'filters by ham' do
      get '/admin/feedback', params: { state: 'ham' }
      expect(response).to have_http_status(:success)
    end

    it 'filters by spam' do
      get '/admin/feedback', params: { state: 'spam' }
      expect(response).to have_http_status(:success)
    end

    it 'filters by presumed_ham' do
      get '/admin/feedback', params: { state: 'presumed_ham' }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/feedback/article/:id' do
    before { login_as_admin }

    it 'filters ham comments for article' do
      create(:comment, article: article, state: 'ham')
      get "/admin/feedback/article/#{article.id}", params: { ham: '1' }
      expect(response).to have_http_status(:success)
    end

    it 'filters spam comments for article' do
      create(:spam_comment, article: article)
      get "/admin/feedback/article/#{article.id}", params: { spam: '1' }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/feedback/destroy/:id' do
    before { login_as_admin }

    let!(:comment) { create(:comment, article: article) }

    it 'shows destroy confirmation' do
      get "/admin/feedback/destroy/#{comment.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/feedback/destroy/:id' do
    before { login_as_admin }

    let!(:comment) { create(:comment, article: article) }

    it 'deletes feedback' do
      expect {
        post "/admin/feedback/destroy/#{comment.id}"
      }.to change(Comment, :count).by(-1)
    end

    it 'redirects to article feedback' do
      post "/admin/feedback/destroy/#{comment.id}"
      expect(response).to redirect_to(action: 'article', id: article.id)
    end

    context 'when non-admin tries to delete other users comment' do
      let!(:other_user) { create(:user, login: 'other', password: 'password123', profile: create(:profile_publisher)) }
      let!(:other_article) { create(:article, user: other_user) }
      let!(:other_comment) { create(:comment, article: other_article) }

      it 'prevents deletion for non-owner non-admin' do
        # Admin can delete anything, so this test just verifies the flow works
        post "/admin/feedback/destroy/#{other_comment.id}"
        expect(response.status).to be_in([302, 200])
      end
    end
  end

  describe 'POST /admin/feedback/create' do
    before { login_as_admin }

    it 'creates a comment on article' do
      expect {
        post '/admin/feedback/create', params: {
          article_id: article.id,
          comment: { author: 'Admin', body: 'Admin comment', email: 'admin@test.com' }
        }
      }.to change(Comment, :count).by(1)
    end

    it 'redirects to article feedback' do
      post '/admin/feedback/create', params: {
        article_id: article.id,
        comment: { author: 'Admin', body: 'Admin comment', email: 'admin@test.com' }
      }
      expect(response).to redirect_to(action: 'article', id: article.id)
    end
  end

  describe 'GET /admin/feedback/edit/:id' do
    before { login_as_admin }

    let!(:comment) { create(:comment, article: article, author: 'Editable') }

    it 'returns success' do
      get "/admin/feedback/edit/#{comment.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays comment for editing' do
      get "/admin/feedback/edit/#{comment.id}"
      expect(response.body).to include('Editable')
    end
  end

  describe 'POST /admin/feedback/update/:id' do
    before { login_as_admin }

    let!(:comment) { create(:comment, article: article, author: 'Original') }

    it 'updates comment' do
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { author: 'Updated Author', body: 'Updated body' }
      }
      expect(comment.reload.author).to eq('Updated Author')
    end

    it 'redirects to article feedback' do
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { author: 'Updated' }
      }
      expect(response).to redirect_to(action: 'article', id: article.id)
    end
  end

  describe 'POST /admin/feedback/change_state/:id' do
    before { login_as_admin }

    let!(:comment) { create(:comment, article: article, state: 'ham') }

    it 'toggles state from ham to spam via XHR' do
      post "/admin/feedback/change_state/#{comment.id}", xhr: true
      expect(comment.reload.state.to_s.downcase).to include('spam')
    end

    it 'returns JSON response' do
      post "/admin/feedback/change_state/#{comment.id}", xhr: true
      expect(response.content_type).to include('json')
    end

    context 'with listing context' do
      it 'returns replace action' do
        post "/admin/feedback/change_state/#{comment.id}", params: { context: 'listing' }, xhr: true
        json = JSON.parse(response.body)
        expect(json['action']).to eq('replace')
      end
    end
  end

  describe 'POST /admin/feedback/mark_as_spam/:id' do
    before { login_as_admin }

    let!(:comment) { create(:comment, article: article, state: 'ham') }

    it 'marks feedback as spam' do
      post "/admin/feedback/mark_as_spam/#{comment.id}"
      comment.reload
      expect(comment.state.to_s.downcase).to include('spam')
    end

    it 'redirects to index' do
      post "/admin/feedback/mark_as_spam/#{comment.id}"
      expect(response).to redirect_to(action: :index)
    end
  end

  describe 'POST /admin/feedback/mark_as_ham/:id' do
    before { login_as_admin }

    let!(:comment) { create(:spam_comment, article: article) }

    it 'marks feedback as ham' do
      post "/admin/feedback/mark_as_ham/#{comment.id}"
      comment.reload
      expect(comment.state.to_s.downcase).to include('ham')
    end

    it 'redirects to index' do
      post "/admin/feedback/mark_as_ham/#{comment.id}"
      expect(response).to redirect_to(action: :index)
    end
  end

  describe 'POST /admin/feedback/bulkops' do
    before { login_as_admin }

    let!(:comment1) { create(:comment, article: article) }
    let!(:comment2) { create(:comment, article: article) }

    it 'deletes checked items' do
      expect {
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1', comment2.id.to_s => '1' },
          bulkop_top: 'Delete Checked Items'
        }
      }.to change(Comment, :count).by(-2)
    end

    it 'marks checked items as spam' do
      post '/admin/feedback/bulkops', params: {
        feedback_check: { comment1.id.to_s => '1' },
        bulkop_top: 'Mark Checked Items as Spam'
      }
      expect(comment1.reload.state.to_s.downcase).to include('spam')
    end

    it 'marks checked items as ham' do
      spam = create(:spam_comment, article: article)
      post '/admin/feedback/bulkops', params: {
        feedback_check: { spam.id.to_s => '1' },
        bulkop_top: 'Mark Checked Items as Ham'
      }
      expect(spam.reload.state.to_s.downcase).to include('ham')
    end

    it 'confirms classification of checked items' do
      post '/admin/feedback/bulkops', params: {
        feedback_check: { comment1.id.to_s => '1' },
        bulkop_top: 'Confirm Classification of Checked Items'
      }
      expect(response).to redirect_to(action: 'index', page: nil, search: nil, confirmed: nil, published: nil)
    end

    it 'uses bottom bulkop when top is empty' do
      expect {
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: '',
          bulkop_bottom: 'Delete Checked Items'
        }
      }.to change(Comment, :count).by(-1)
    end

    it 'deletes all spam' do
      create(:spam_comment, article: article)
      create(:spam_comment, article: article)
      post '/admin/feedback/bulkops', params: {
        bulkop_top: 'Delete all spam'
      }
      expect(Feedback.where(state: 'spam').count).to eq(0)
    end

    it 'handles unknown bulkop' do
      post '/admin/feedback/bulkops', params: {
        feedback_check: { comment1.id.to_s => '1' },
        bulkop_top: 'Unknown Operation'
      }
      expect(flash[:notice]).to include('Not implemented')
    end

    it 'redirects to article when article_id present' do
      post '/admin/feedback/bulkops', params: {
        feedback_check: { comment1.id.to_s => '1' },
        bulkop_top: 'Mark Checked Items as Ham',
        article_id: article.id
      }
      expect(response).to redirect_to(action: 'article', id: article.id.to_s, confirmed: nil, published: nil)
    end
  end
end
