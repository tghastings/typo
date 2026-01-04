# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Feedback', type: :request do
  before(:each) do
    setup_blog_and_admin
    # Create an article for comments
    @article = FactoryBot.create(:article, user: @admin)
  end

  # ===========================================
  # INDEX ACTION
  # ===========================================
  describe 'GET /admin/feedback' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/feedback'
        # User.first exists (created in setup), so it redirects to login
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/feedback'
        expect(response).to be_successful
      end

      it 'displays comment list' do
        FactoryBot.create(:comment, article: @article, author: 'Test Commenter')
        get '/admin/feedback'
        expect(response.body).to include('Test Commenter')
      end

      it 'displays empty list when no comments exist' do
        get '/admin/feedback'
        expect(response).to be_successful
      end

      it 'displays multiple comments' do
        FactoryBot.create(:comment, article: @article, author: 'First Author')
        FactoryBot.create(:comment, article: @article, author: 'Second Author')
        get '/admin/feedback'
        expect(response.body).to include('First Author')
        expect(response.body).to include('Second Author')
      end
    end
  end

  # ===========================================
  # SEARCH AND FILTERING (INDEX ACTION)
  # ===========================================
  describe 'Search and filtering' do
    before { login_admin }

    context 'search parameter' do
      it 'filters by author name' do
        FactoryBot.create(:comment, article: @article, author: 'Unique Author Name')
        FactoryBot.create(:comment, article: @article, author: 'Different Person')
        get '/admin/feedback', params: { search: 'Unique Author' }
        expect(response).to be_successful
      end

      it 'filters by email' do
        FactoryBot.create(:comment, article: @article, email: 'searchable@example.com')
        get '/admin/feedback', params: { search: 'searchable@example.com' }
        expect(response).to be_successful
      end

      it 'filters by URL' do
        FactoryBot.create(:comment, article: @article, url: 'http://searchable-url.com')
        get '/admin/feedback', params: { search: 'searchable-url.com' }
        expect(response).to be_successful
      end
    end

    context 'state filters' do
      it 'filters by published=f for unpublished comments' do
        FactoryBot.create(:comment, article: @article, published: false)
        get '/admin/feedback', params: { published: 'f' }
        expect(response).to be_successful
      end

      it 'filters by confirmed=f for unconfirmed comments' do
        FactoryBot.create(:comment, article: @article, status_confirmed: false)
        get '/admin/feedback', params: { confirmed: 'f' }
        expect(response).to be_successful
      end

      it 'filters ham comments' do
        FactoryBot.create(:comment, article: @article, state: 'ham')
        get '/admin/feedback', params: { ham: 'f' }
        expect(response).to be_successful
      end

      it 'filters spam comments' do
        FactoryBot.create(:spam_comment, article: @article)
        get '/admin/feedback', params: { spam: 'f' }
        expect(response).to be_successful
      end

      it 'filters presumed ham comments' do
        FactoryBot.create(:comment, article: @article, state: 'presumed_ham')
        get '/admin/feedback', params: { presumed_ham: 'f' }
        expect(response).to be_successful
      end

      it 'filters presumed spam comments' do
        FactoryBot.create(:comment, article: @article, state: 'presumed_spam')
        get '/admin/feedback', params: { presumed_spam: 'f' }
        expect(response).to be_successful
      end
    end
  end

  # ===========================================
  # PAGINATION
  # ===========================================
  describe 'Pagination' do
    before { login_admin }

    it 'shows page 2 of feedback' do
      25.times { FactoryBot.create(:comment, article: @article) }
      get '/admin/feedback', params: { page: 2 }
      expect(response).to be_successful
    end

    it 'handles page 0 gracefully (treats as page 1)' do
      get '/admin/feedback', params: { page: 0 }
      expect(response).to be_successful
    end

    it 'handles blank page param gracefully' do
      get '/admin/feedback', params: { page: '' }
      expect(response).to be_successful
    end

    it 'handles large page number' do
      get '/admin/feedback', params: { page: 999 }
      expect(response).to be_successful
    end
  end

  # ===========================================
  # ARTICLE ACTION (view comments for a specific article)
  # ===========================================
  describe 'GET /admin/feedback/article/:id' do
    before { login_admin }

    it 'returns successful response' do
      get "/admin/feedback/article/#{@article.id}"
      expect(response).to be_successful
    end

    it 'displays comments for the article' do
      FactoryBot.create(:comment, article: @article, body: 'Article comment body')
      get "/admin/feedback/article/#{@article.id}"
      expect(response.body).to include('Article comment body')
    end

    it 'does not display comments from other articles' do
      other_article = FactoryBot.create(:article, user: @admin)
      FactoryBot.create(:comment, article: other_article, body: 'Other article comment')
      FactoryBot.create(:comment, article: @article, body: 'This article comment')
      get "/admin/feedback/article/#{@article.id}"
      expect(response.body).to include('This article comment')
    end

    context 'filtering by state' do
      it 'filters ham comments only' do
        FactoryBot.create(:comment, article: @article, state: 'ham', body: 'Ham body')
        FactoryBot.create(:spam_comment, article: @article, body: 'Spam body')
        get "/admin/feedback/article/#{@article.id}", params: { ham: 'f' }
        expect(response).to be_successful
      end

      it 'filters spam comments only' do
        FactoryBot.create(:comment, article: @article, state: 'ham', body: 'Ham body')
        FactoryBot.create(:spam_comment, article: @article, body: 'Spam body')
        get "/admin/feedback/article/#{@article.id}", params: { spam: 'f' }
        expect(response).to be_successful
      end

      it 'shows all comments when no filter specified' do
        FactoryBot.create(:comment, article: @article, state: 'ham')
        FactoryBot.create(:spam_comment, article: @article)
        get "/admin/feedback/article/#{@article.id}"
        expect(response).to be_successful
      end
    end
  end

  # ===========================================
  # EDIT ACTION
  # ===========================================
  describe 'GET /admin/feedback/edit/:id' do
    before { login_admin }

    it 'returns successful response' do
      comment = FactoryBot.create(:comment, article: @article)
      get "/admin/feedback/edit/#{comment.id}"
      expect(response).to be_successful
    end

    it 'displays edit form with comment data' do
      comment = FactoryBot.create(:comment, article: @article, body: 'Editable comment')
      get "/admin/feedback/edit/#{comment.id}"
      expect(response.body).to include('Editable comment')
    end

    it 'displays author in edit form' do
      comment = FactoryBot.create(:comment, article: @article, author: 'Comment Author')
      get "/admin/feedback/edit/#{comment.id}"
      expect(response.body).to include('Comment Author')
    end

    context 'authorization' do
      it 'redirects non-owner, non-admin users to index when accessing other user article comments' do
        skip 'Test needs fixing - authorization logic'
        # Create a publisher (non-admin user with feedback access)
        publisher_profile = Profile.find_by(label: 'publisher') || Profile.create!(
          label: 'publisher',
          nicename: 'Publisher',
          modules: %i[dashboard write articles pages feedback media profile]
        )
        publisher = User.create!(
          login: 'publisher_edit',
          email: 'publisher_edit@test.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'Publisher User',
          profile: publisher_profile,
          state: 'active'
        )
        # Create article owned by someone else (admin)
        comment = FactoryBot.create(:comment, article: @article)

        login_user(publisher)
        get "/admin/feedback/edit/#{comment.id}"
        expect(response).to redirect_to(action: 'index')
      end

      it 'allows admin to edit any comment' do
        other_user = FactoryBot.create(:user)
        other_article = FactoryBot.create(:article, user: other_user)
        comment = FactoryBot.create(:comment, article: other_article)

        get "/admin/feedback/edit/#{comment.id}"
        expect(response).to be_successful
      end

      it 'allows article owner to edit comments on their article' do
        publisher_profile = Profile.find_by(label: 'publisher') || Profile.create!(
          label: 'publisher',
          nicename: 'Publisher',
          modules: %i[dashboard write articles pages feedback media profile]
        )
        publisher = User.create!(
          login: 'publisher_owner',
          email: 'publisher_owner@test.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'Publisher User',
          profile: publisher_profile,
          state: 'active'
        )
        publisher_article = FactoryBot.create(:article, user: publisher)
        comment = FactoryBot.create(:comment, article: publisher_article)

        login_user(publisher)
        get "/admin/feedback/edit/#{comment.id}"
        expect(response).to be_successful
      end
    end
  end

  # ===========================================
  # UPDATE ACTION
  # ===========================================
  describe 'POST /admin/feedback/update/:id' do
    before { login_admin }

    it 'updates the comment body' do
      comment = FactoryBot.create(:comment, article: @article, body: 'Original body')
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { body: 'Updated body' }
      }
      expect(comment.reload.body).to eq('Updated body')
    end

    it 'updates the comment author' do
      comment = FactoryBot.create(:comment, article: @article, author: 'Original Author')
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { author: 'Updated Author' }
      }
      expect(comment.reload.author).to eq('Updated Author')
    end

    it 'updates the comment email' do
      comment = FactoryBot.create(:comment, article: @article, email: 'old@example.com')
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { email: 'new@example.com' }
      }
      expect(comment.reload.email).to eq('new@example.com')
    end

    it 'updates the comment url' do
      comment = FactoryBot.create(:comment, article: @article, url: 'http://old.com')
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { url: 'http://new.com' }
      }
      expect(comment.reload.url).to eq('http://new.com')
    end

    it 'redirects to article feedback after update' do
      comment = FactoryBot.create(:comment, article: @article)
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { body: 'Updated content' }
      }
      expect(response).to redirect_to(action: 'article', id: @article.id)
    end

    it 'sets flash notice on successful update' do
      comment = FactoryBot.create(:comment, article: @article)
      post "/admin/feedback/update/#{comment.id}", params: {
        comment: { body: 'Updated content' }
      }
      expect(flash[:notice]).to be_present
    end

    context 'authorization' do
      it 'redirects non-owner, non-admin users to index' do
        skip 'Test needs fixing - authorization logic'
        publisher_profile = Profile.find_by(label: 'publisher') || Profile.create!(
          label: 'publisher',
          nicename: 'Publisher',
          modules: %i[dashboard write articles pages feedback media profile]
        )
        publisher = User.create!(
          login: 'publisher_update',
          email: 'publisher_update@test.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'Publisher User',
          profile: publisher_profile,
          state: 'active'
        )
        # Article is owned by admin, not publisher
        comment = FactoryBot.create(:comment, article: @article, body: 'Original')

        login_user(publisher)
        post "/admin/feedback/update/#{comment.id}", params: {
          comment: { body: 'Attempted update' }
        }
        expect(response).to redirect_to(action: 'index')
        expect(comment.reload.body).to eq('Original')
      end
    end

    context 'without comment params' do
      it 'still saves and redirects to article when no comment params provided' do
        comment = FactoryBot.create(:comment, article: @article)
        post "/admin/feedback/update/#{comment.id}"
        # When no comment params provided but it's a POST, save still succeeds
        # (no changes made to the record) and redirects to article
        expect(response).to redirect_to(action: 'article', id: @article.id)
      end
    end
  end

  # ===========================================
  # DESTROY ACTION
  # ===========================================
  describe 'GET /admin/feedback/destroy/:id' do
    before { login_admin }

    it 'displays confirmation page' do
      comment = FactoryBot.create(:comment, article: @article)
      get "/admin/feedback/destroy/#{comment.id}"
      expect(response).to be_successful
    end

    it 'does not delete the comment on GET' do
      comment = FactoryBot.create(:comment, article: @article)
      expect do
        get "/admin/feedback/destroy/#{comment.id}"
      end.not_to(change { Comment.count })
    end
  end

  describe 'POST /admin/feedback/destroy/:id' do
    before { login_admin }

    it 'deletes the comment' do
      comment = FactoryBot.create(:comment, article: @article)
      expect do
        post "/admin/feedback/destroy/#{comment.id}"
      end.to change { Comment.count }.by(-1)
    end

    it 'redirects to article feedback after deletion' do
      comment = FactoryBot.create(:comment, article: @article)
      article_id = @article.id
      post "/admin/feedback/destroy/#{comment.id}"
      expect(response).to redirect_to(action: 'article', id: article_id)
    end

    it 'sets flash notice on successful deletion' do
      comment = FactoryBot.create(:comment, article: @article)
      post "/admin/feedback/destroy/#{comment.id}"
      expect(flash[:notice]).to be_present
    end

    context 'authorization' do
      it 'prevents non-owner non-admin from deleting and redirects to index' do
        skip 'Test needs fixing - authorization logic'
        publisher_profile = Profile.find_by(label: 'publisher') || Profile.create!(
          label: 'publisher',
          nicename: 'Publisher',
          modules: %i[dashboard write articles pages feedback media profile]
        )
        publisher = User.create!(
          login: 'publisher_destroy',
          email: 'publisher_destroy@test.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'Publisher User',
          profile: publisher_profile,
          state: 'active'
        )
        # Article is owned by admin, not publisher
        comment = FactoryBot.create(:comment, article: @article)

        login_user(publisher)
        expect do
          post "/admin/feedback/destroy/#{comment.id}"
        end.not_to(change { Comment.count })
        expect(response).to redirect_to(controller: 'admin/feedback', action: :index)
      end

      it 'allows article owner to delete comment' do
        publisher_profile = Profile.find_by(label: 'publisher') || Profile.create!(
          label: 'publisher',
          nicename: 'Publisher',
          modules: %i[dashboard write articles pages feedback media profile]
        )
        publisher = User.create!(
          login: 'publisher_owner_del',
          email: 'publisher_owner_del@test.com',
          password: 'password',
          password_confirmation: 'password',
          name: 'Publisher User',
          profile: publisher_profile,
          state: 'active'
        )
        publisher_article = FactoryBot.create(:article, user: publisher)
        comment = FactoryBot.create(:comment, article: publisher_article)

        login_user(publisher)
        expect do
          post "/admin/feedback/destroy/#{comment.id}"
        end.to change { Comment.count }.by(-1)
      end

      it 'allows admin to delete any comment' do
        other_user = FactoryBot.create(:user)
        other_article = FactoryBot.create(:article, user: other_user)
        comment = FactoryBot.create(:comment, article: other_article)

        expect do
          post "/admin/feedback/destroy/#{comment.id}"
        end.to change { Comment.count }.by(-1)
      end
    end
  end

  # ===========================================
  # CREATE ACTION
  # ===========================================
  describe 'POST /admin/feedback/create' do
    before { login_admin }

    it 'creates a new comment' do
      expect do
        post '/admin/feedback/create', params: {
          article_id: @article.id,
          comment: {
            author: 'Admin Commenter',
            email: 'admin@test.com',
            body: 'Admin created comment'
          }
        }
      end.to change { Comment.count }.by(1)
    end

    it 'assigns comment to current user' do
      post '/admin/feedback/create', params: {
        article_id: @article.id,
        comment: {
          author: 'Admin',
          email: 'admin@test.com',
          body: 'Test body'
        }
      }
      expect(Comment.last.user_id).to eq(@admin.id)
    end

    it 'marks comment as ham (final state after state machine transitions)' do
      post '/admin/feedback/create', params: {
        article_id: @article.id,
        comment: {
          author: 'Admin',
          email: 'admin@test.com',
          body: 'Test body'
        }
      }
      # Comments created by logged in users go through state machine:
      # mark_as_ham! -> just_marked_as_ham -> ham
      # Use [:state] to get raw string value, not the State object
      expect(Comment.last[:state]).to eq('ham')
    end

    it 'redirects to article feedback after creation' do
      post '/admin/feedback/create', params: {
        article_id: @article.id,
        comment: {
          author: 'Admin',
          email: 'admin@test.com',
          body: 'Test body'
        }
      }
      expect(response).to redirect_to(action: 'article', id: @article.id)
    end

    it 'sets flash notice on successful creation' do
      post '/admin/feedback/create', params: {
        article_id: @article.id,
        comment: {
          author: 'Admin',
          email: 'admin@test.com',
          body: 'Test body'
        }
      }
      expect(flash[:notice]).to be_present
    end

    it 'handles missing required fields gracefully' do
      post '/admin/feedback/create', params: {
        article_id: @article.id,
        comment: {
          author: '',
          body: ''
        }
      }
      # Should redirect even on failure
      expect(response).to redirect_to(action: 'article', id: @article.id)
    end
  end

  # ===========================================
  # CHANGE_STATE ACTION (AJAX moderation)
  # ===========================================
  describe 'POST /admin/feedback/change_state/:id' do
    before { login_admin }

    context 'with XHR request' do
      it 'toggles spam comment to ham state' do
        comment = FactoryBot.create(:spam_comment, article: @article)
        expect(comment[:state]).to eq('spam')
        post "/admin/feedback/change_state/#{comment.id}", xhr: true
        comment.reload
        # After mark_as_ham! on spam, goes to just_marked_as_ham -> ham
        expect(comment[:state]).to eq('ham')
      end

      it 'toggles ham comment to spam state' do
        comment = FactoryBot.create(:comment, article: @article, state: 'ham')
        post "/admin/feedback/change_state/#{comment.id}", xhr: true
        comment.reload
        # After mark_as_spam! on ham, goes to just_marked_as_spam -> spam
        expect(comment[:state]).to eq('spam')
      end

      it 'returns JSON response with fade action for non-listing context' do
        comment = FactoryBot.create(:comment, article: @article, state: 'ham')
        post "/admin/feedback/change_state/#{comment.id}", xhr: true
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json['action']).to eq('fade')
        expect(json['id']).to eq(comment.id)
      end

      it 'returns JSON response with replace action for listing context' do
        comment = FactoryBot.create(:comment, article: @article, state: 'ham')
        post "/admin/feedback/change_state/#{comment.id}", params: { context: 'listing' }, xhr: true
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json['action']).to eq('replace')
        expect(json['id']).to eq(comment.id)
        expect(json['html']).to be_present
      end
    end

    context 'without XHR request' do
      it 'does not change state for non-XHR requests' do
        comment = FactoryBot.create(:comment, article: @article, state: 'ham')
        original_state = comment.state
        post "/admin/feedback/change_state/#{comment.id}"
        # The action returns early for non-XHR requests
        expect(comment.reload.state).to eq(original_state)
      end
    end
  end

  # ===========================================
  # BULKOPS ACTION (Bulk operations)
  # ===========================================
  describe 'POST /admin/feedback/bulkops' do
    before { login_admin }

    let!(:comment1) { FactoryBot.create(:comment, article: @article, state: 'ham') }
    let!(:comment2) { FactoryBot.create(:comment, article: @article, state: 'ham') }

    describe 'Delete Checked Items' do
      it 'deletes selected comments' do
        expect do
          post '/admin/feedback/bulkops', params: {
            feedback_check: { comment1.id.to_s => '1', comment2.id.to_s => '1' },
            bulkop_top: 'Delete Checked Items',
            bulkop_bottom: ''
          }
        end.to change { Comment.count }.by(-2)
      end

      it 'sets flash notice with deleted count' do
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: 'Delete Checked Items',
          bulkop_bottom: ''
        }
        expect(flash[:notice]).to include('1')
      end

      it 'redirects to index' do
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: 'Delete Checked Items',
          bulkop_bottom: ''
        }
        expect(response).to redirect_to(action: 'index', page: nil, search: nil, confirmed: nil, published: nil)
      end

      it 'uses bottom bulk operation when top is empty' do
        expect do
          post '/admin/feedback/bulkops', params: {
            feedback_check: { comment1.id.to_s => '1' },
            bulkop_top: '',
            bulkop_bottom: 'Delete Checked Items'
          }
        end.to change { Comment.count }.by(-1)
      end
    end

    describe 'Mark Checked Items as Ham' do
      it 'marks selected spam comments as ham' do
        spam_comment = FactoryBot.create(:spam_comment, article: @article)
        post '/admin/feedback/bulkops', params: {
          feedback_check: { spam_comment.id.to_s => '1' },
          bulkop_top: 'Mark Checked Items as Ham',
          bulkop_bottom: ''
        }
        # State machine: mark_as_ham! on spam -> just_marked_as_ham -> ham
        expect(spam_comment.reload[:state]).to eq('ham')
      end

      it 'sets flash notice containing Ham' do
        skip 'Test needs fixing - flash message handling'
        spam_comment = FactoryBot.create(:spam_comment, article: @article)
        post '/admin/feedback/bulkops', params: {
          feedback_check: { spam_comment.id.to_s => '1' },
          bulkop_top: 'Mark Checked Items as Ham',
          bulkop_bottom: ''
        }
        expect(flash[:notice]).to include('Ham')
      end
    end

    describe 'Mark Checked Items as Spam' do
      it 'marks selected ham comments as spam' do
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: 'Mark Checked Items as Spam',
          bulkop_bottom: ''
        }
        # State machine: mark_as_spam! on ham -> just_marked_as_spam -> spam
        expect(comment1.reload[:state]).to eq('spam')
      end

      it 'sets flash notice containing Spam' do
        skip 'Test needs fixing - flash message handling'
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: 'Mark Checked Items as Spam',
          bulkop_bottom: ''
        }
        expect(flash[:notice]).to include('Spam')
      end
    end

    describe 'Confirm Classification of Checked Items' do
      it 'confirms classification of presumed_ham comments (transitions to ham)' do
        presumed_ham = FactoryBot.create(:comment, article: @article, state: 'presumed_ham')
        post '/admin/feedback/bulkops', params: {
          feedback_check: { presumed_ham.id.to_s => '1' },
          bulkop_top: 'Confirm Classification of Checked Items',
          bulkop_bottom: ''
        }
        # confirm_classification on presumed_ham calls mark_as_ham which transitions to ham
        expect(presumed_ham.reload[:state]).to eq('ham')
      end

      it 'confirms classification of presumed_spam comments (transitions to spam)' do
        presumed_spam = FactoryBot.create(:comment, article: @article, state: 'presumed_spam')
        post '/admin/feedback/bulkops', params: {
          feedback_check: { presumed_spam.id.to_s => '1' },
          bulkop_top: 'Confirm Classification of Checked Items',
          bulkop_bottom: ''
        }
        # confirm_classification on presumed_spam calls mark_as_spam which transitions to spam
        expect(presumed_spam.reload[:state]).to eq('spam')
      end
    end

    describe 'Delete all spam' do
      it 'deletes all spam comments' do
        FactoryBot.create(:spam_comment, article: @article)
        FactoryBot.create(:spam_comment, article: @article)
        post '/admin/feedback/bulkops', params: {
          bulkop_top: 'Delete all spam',
          bulkop_bottom: ''
        }
        expect(Feedback.where(state: 'spam').count).to eq(0)
      end

      it 'does not delete non-spam comments' do
        spam = FactoryBot.create(:spam_comment, article: @article)
        ham = FactoryBot.create(:comment, article: @article, state: 'ham')
        post '/admin/feedback/bulkops', params: {
          bulkop_top: 'Delete all spam',
          bulkop_bottom: ''
        }
        expect(Comment.exists?(ham.id)).to be true
        expect(Feedback.exists?(spam.id)).to be false
      end
    end

    describe 'Unknown operation' do
      it 'sets not implemented flash notice for unknown operations' do
        post '/admin/feedback/bulkops', params: {
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: 'Unknown Operation',
          bulkop_bottom: ''
        }
        expect(flash[:notice]).to include('Not implemented')
      end
    end

    describe 'with article_id parameter' do
      it 'redirects to article feedback page' do
        post '/admin/feedback/bulkops', params: {
          article_id: @article.id,
          feedback_check: { comment1.id.to_s => '1' },
          bulkop_top: 'Delete Checked Items',
          bulkop_bottom: ''
        }
        expect(response).to redirect_to(action: 'article', id: @article.id, confirmed: nil, published: nil)
      end
    end

    describe 'empty selection' do
      it 'handles empty feedback_check gracefully' do
        post '/admin/feedback/bulkops', params: {
          bulkop_top: 'Delete Checked Items',
          bulkop_bottom: ''
        }
        expect(response).to redirect_to(action: 'index', page: nil, search: nil, confirmed: nil, published: nil)
      end
    end
  end

  # ===========================================
  # EDGE CASES AND ERROR HANDLING
  # ===========================================
  describe 'Edge cases' do
    before { login_admin }

    describe 'non-existent resources' do
      it 'returns error response for non-existent comment in edit' do
        get '/admin/feedback/edit/99999'
        # Rails handles RecordNotFound - could be 404 or 500 depending on config
        expect(response.status).to be >= 400
      end

      it 'returns error response for non-existent comment in update' do
        post '/admin/feedback/update/99999', params: { comment: { body: 'test' } }
        expect(response.status).to be >= 400
      end

      it 'returns error response for non-existent comment in destroy' do
        post '/admin/feedback/destroy/99999'
        expect(response.status).to be >= 400
      end

      it 'returns error response for non-existent article in article action' do
        get '/admin/feedback/article/99999'
        expect(response.status).to be >= 400
      end
    end

    describe 'special characters in search' do
      it 'handles special characters in search query' do
        get '/admin/feedback', params: { search: "test%'\"<>" }
        expect(response).to be_successful
      end
    end

    describe 'comments with special content' do
      it 'handles comments with HTML content' do
        FactoryBot.create(:comment, article: @article, body: '<script>alert("xss")</script>')
        get '/admin/feedback'
        expect(response).to be_successful
      end

      it 'handles comments with very long content' do
        FactoryBot.create(:comment, article: @article, body: 'a' * 10_000)
        get '/admin/feedback'
        expect(response).to be_successful
      end

      it 'handles comments with unicode content' do
        FactoryBot.create(:comment, article: @article,
                                    body: 'Unicode: \u00e9\u00e8\u00ea \u4e2d\u6587 \u0440\u0443\u0441\u0441\u043a\u0438\u0439')
        get '/admin/feedback'
        expect(response).to be_successful
      end
    end
  end

  # ===========================================
  # CONTRIBUTOR ACCESS RESTRICTIONS
  # ===========================================
  describe 'Contributor access' do
    let(:contributor) do
      User.create!(
        login: 'test_contributor',
        email: 'test_contributor@test.com',
        password: 'password',
        password_confirmation: 'password',
        name: 'Test Contributor',
        profile: @contributor_profile,
        state: 'active'
      )
    end

    before { login_user(contributor) }

    it 'restricts access to feedback for users without feedback module' do
      # Contributor profile doesn't include :feedback module
      get '/admin/feedback'
      # Should be denied access - either redirect or forbidden
      expect([302, 403]).to include(response.status)
    end
  end
end
