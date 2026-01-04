# frozen_string_literal: true

require 'spec_helper'

describe Admin::FeedbackController do
  render_views

  shared_examples_for 'destroy feedback with feedback from own article' do
    it 'should destroy feedback' do
      id = feedback_from_own_article.id
      expect do
        post 'destroy', id: id
      end.to change(Feedback, :count)
      expect do
        Feedback.find(feedback_from_own_article.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should redirect to feedback from article' do
      post 'destroy', id: feedback_from_own_article.id
      expect(response).to redirect_to(controller: 'admin/feedback', action: 'article',
                                      id: feedback_from_own_article.article.id)
    end

    it 'should not destroy feedback in get request' do
      id = feedback_from_own_article.id
      expect do
        get 'destroy', id: id
      end.not_to change(Feedback, :count)
      expect do
        Feedback.find(feedback_from_own_article.id)
      end.not_to raise_error
      expect(response).to render_template 'destroy'
    end
  end

  describe 'logged in admin user' do
    before :each do
      Factory(:blog)
      # TODO: Delete after removing fixtures
      Profile.delete_all
      @admin = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
      request.session = { user_id: @admin.id }
    end

    def feedback_from_own_article
      @article ||= Factory(:article, user: @admin)
      @feedback_from_own_article ||= Factory.create(:comment, article: @article)
    end

    def feedback_from_not_own_article
      @feedback_from_not_own_article ||= Factory(:spam_comment)
    end

    describe 'destroy action' do
      it_should_behave_like 'destroy feedback with feedback from own article'

      it "should destroy feedback from article doesn't own" do
        id = feedback_from_not_own_article.id
        expect do
          post 'destroy', id: id
        end.to change(Feedback, :count)
        expect do
          Feedback.find(feedback_from_not_own_article.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to redirect_to(controller: 'admin/feedback', action: 'article',
                                        id: feedback_from_not_own_article.article.id)
      end
    end

    describe 'index action' do
      before(:each) do
        # Remove feedback due to some fixtures
        Feedback.delete_all
      end

      def should_success_with_index(response)
        expect(response).to be_success
        expect(response).to render_template('index')
      end

      it 'should success' do
        a = Factory(:article)
        3.times { Factory(:comment, article: a) }
        get :index
        should_success_with_index(response)
        expect(assigns(:feedback).size).to eq(3)
      end

      it 'should view only unconfirmed feedback' do
        c = Factory(:comment, state: 'presumed_ham')
        Factory(:comment)
        get :index, confirmed: 'f'
        should_success_with_index(response)
        expect(assigns(:feedback)).to eq([c])
      end

      it 'should view only spam feedback' do
        Factory(:comment)
        c = Factory(:spam_comment)
        get :index, published: 'f'
        should_success_with_index(response)
        expect(assigns(:feedback)).to eq([c])
      end

      it 'should view unconfirmed_spam' do
        Factory(:comment)
        Factory(:spam_comment)
        c = Factory(:spam_comment, state: 'presumed_spam')
        get :index, published: 'f', confirmed: 'f'
        should_success_with_index(response)
        expect(assigns(:feedback)).to eq([c])
      end

      # TODO: Functionality is counter-intuitive: param presumed_spam is
      # set to f(alse), but shows presumed_spam.
      it 'should view presumed_spam' do
        c = Factory(:comment, state: :presumed_spam)
        Factory(:comment, state: :presumed_ham)
        get :index, presumed_spam: 'f'
        should_success_with_index(response)
        expect(assigns(:feedback)).to eq([c])
      end

      it 'should view presumed_ham' do
        Factory(:comment)
        Factory(:comment, state: :presumed_spam)
        c = Factory(:comment, state: :presumed_ham)
        get :index, presumed_ham: 'f'
        should_success_with_index(response)
        expect(assigns(:feedback)).to eq([c])
      end

      it 'should get page 1 if page params empty' do
        get :index, page: ''
        should_success_with_index(response)
      end
    end

    describe 'article action' do
      def should_success_with_article_view(response)
        expect(response).to be_success
        expect(response).to render_template('article')
      end

      it 'should see all feedback on one article' do
        article = Factory(:article)
        Factory(:comment, article: article)
        Factory(:comment, article: article)
        get :article, id: article.id
        should_success_with_article_view(response)
        expect(assigns(:article)).to eq(article)
        expect(assigns(:feedback).size).to eq(2)
      end

      it 'should see only spam feedback on one article' do
        article = Factory(:article)
        Factory(:comment, state: 'spam', article: article)
        get :article, id: article.id, spam: 'y'
        should_success_with_article_view(response)
        expect(assigns(:article)).to eq(article)
        expect(assigns(:feedback).size).to eq(1)
      end

      it 'should see only ham feedback on one article' do
        article = Factory(:article)
        Factory(:comment, article: article)
        get :article, id: article.id, ham: 'y'
        should_success_with_article_view(response)
        expect(assigns(:article)).to eq(article)
        expect(assigns(:feedback).size).to eq(1)
      end

      it 'should redirect_to index if bad article id' do
        expect do
          get :article, id: 102_302
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'create action' do
      def base_comment(options = {})
        { 'body' => 'a new comment', 'author' => 'Me', 'url' => 'http://typosphere.org',
          'email' => 'dev@typosphere.org' }.merge(options)
      end

      describe 'by get access' do
        it "should raise ActiveRecordNotFound if article doesn't exist" do
          expect do
            get 'create', article_id: 120_431, comment: base_comment
          end.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'should not create comment' do
          article = Factory(:article)
          expect do
            get 'create', article_id: article.id, comment: base_comment
            expect(response).to redirect_to(action: 'article', id: article.id)
          end.not_to change(Comment, :count)
        end
      end

      describe 'by post access' do
        it "should raise ActiveRecordNotFound if article doesn't exist" do
          expect do
            post 'create', article_id: 123_104, comment: base_comment
          end.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'should create comment' do
          article = Factory(:article)
          expect do
            post 'create', article_id: article.id, comment: base_comment
            expect(response).to redirect_to(action: 'article', id: article.id)
          end.to change(Comment, :count)
        end

        it 'should create comment mark as ham' do
          article = Factory(:article)
          expect do
            post 'create', article_id: article.id, comment: base_comment
            expect(response).to redirect_to(action: 'article', id: article.id)
          end.to(change { Comment.where(state: 'ham').count })
        end
      end
    end

    describe 'edit action' do
      it 'should render edit form' do
        article = Factory(:article)
        comment = Factory(:comment, article: article)
        get 'edit', id: comment.id
        expect(assigns(:comment)).to eq(comment)
        expect(assigns(:article)).to eq(article)
        expect(response).to be_success
        expect(response).to render_template('edit')
      end
    end

    describe 'update action' do
      it 'should update comment if post request' do
        article = Factory(:article)
        comment = Factory(:comment, article: article)
        post 'update', id: comment.id,
                       comment: { author: 'Bob Foo2',
                                  url: 'http://fakeurl.com',
                                  body: 'updated comment' }
        expect(response).to redirect_to(action: 'article', id: article.id)
        comment.reload
        expect(comment.body).to eq('updated comment')
      end

      it 'should not  update comment if get request' do
        comment = Factory(:comment)
        get 'update', id: comment.id,
                      comment: { author: 'Bob Foo2',
                                 url: 'http://fakeurl.com',
                                 body: 'updated comment' }
        expect(response).to redirect_to(action: 'edit', id: comment.id)
        comment.reload
        expect(comment.body).not_to eq('updated comment')
      end
    end
  end

  describe 'publisher access' do
    before :each do
      Factory(:blog)
      # TODO: remove this delete_all after removing all fixture
      Profile.delete_all
      @publisher = Factory(:user, profile: Factory(:profile_publisher))
      request.session = { user_id: @publisher.id }
    end

    def feedback_from_own_article
      @article ||= Factory(:article, user: @publisher)
      @feedback_from_own_article ||= Factory(:comment, article: @article)
    end

    def feedback_from_not_own_article
      @article ||= Factory(:article, user: Factory(:user, login: 'other_user'))
      @feedback_from_not_own_article ||= Factory(:comment, article: @article)
    end

    describe 'destroy action' do
      it_should_behave_like 'destroy feedback with feedback from own article'

      it "should not destroy feedback doesn't own" do
        id = feedback_from_not_own_article.id
        expect(Feedback).to receive(:find).with(id.to_s).and_return(feedback_from_not_own_article)
        feedback_from_not_own_article.article
        post 'destroy', id: id
        expect(response).to redirect_to(controller: 'admin/feedback', action: 'index')
      end
    end

    describe 'edit action' do
      it 'should not edit comment no own article' do
        get 'edit', id: feedback_from_not_own_article.id
        expect(response).to redirect_to(action: 'index')
      end

      it 'should edit comment if own article' do
        get 'edit', id: feedback_from_own_article.id
        expect(response).to be_success
        expect(response).to render_template('edit')
        expect(assigns(:comment)).to eq(feedback_from_own_article)
        expect(assigns(:article)).to eq(feedback_from_own_article.article)
      end
    end

    describe 'update action' do
      it 'should update comment if own article' do
        post 'update', id: feedback_from_own_article.id,
                       comment: { author: 'Bob Foo2',
                                  url: 'http://fakeurl.com',
                                  body: 'updated comment' }
        expect(response).to redirect_to(action: 'article', id: feedback_from_own_article.article.id)
        feedback_from_own_article.reload
        expect(feedback_from_own_article.body).to eq('updated comment')
      end

      it 'should not update comment if not own article' do
        post 'update', id: feedback_from_not_own_article.id,
                       comment: { author: 'Bob Foo2',
                                  url: 'http://fakeurl.com',
                                  body: 'updated comment' }
        expect(response).to redirect_to(action: 'index')
        feedback_from_not_own_article.reload
        expect(feedback_from_not_own_article.body).not_to eq('updated comment')
      end
    end

    describe '#bulkops action' do
      it 'should redirect to action' do
        post :bulkops, bulkop_top: 'destroy all spam'
        expect(response).to redirect_to(action: 'index')
      end
    end
  end
end
