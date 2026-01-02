 require 'spec_helper'

describe Admin::ContentController do
  render_views

  # Like it's a shared, need call everywhere
  shared_examples_for 'index action' do

    it 'should render template index' do
      get 'index'
      expect(response).to render_template('index')
    end

    it 'should see all published in index' do
      get :index, :search => {:published => '0', :published_at => '2008-08', :user_id => '2'}
      expect(response).to render_template('index')
      expect(response).to be_success
    end

    it 'should restrict only by searchstring' do
      article = Factory(:article, :body => 'once uppon an originally time')
      get :index, :search => {:searchstring => 'originally'}
      expect(assigns(:articles)).to eq([article])
      expect(response).to render_template('index')
      expect(response).to be_success
    end

    it 'should restrict by searchstring and published_at' do
      Factory(:article)
      get :index, :search => {:searchstring => 'originally', :published_at => '2008-08'}
      expect(assigns(:articles)).to be_empty
      expect(response).to render_template('index')
      expect(response).to be_success
    end

    it 'should restrict to drafts' do
      article = Factory(:article, :state => 'draft')
      get :index, :search => {:state => 'drafts'}
      expect(assigns(:articles)).to eq([article])
      expect(response).to render_template('index')
      expect(response).to be_success
    end

    it 'should restrict to publication pending articles' do
      article = Factory(:article, :state => 'publication_pending', :published_at => (Time.now + 1.day).to_s)
      get :index, :search => {:state => 'pending'}
      expect(assigns(:articles)).to eq([article])
      expect(response).to render_template('index')
      expect(response).to be_success
    end
    
    it 'should restrict to withdrawn articles' do
      article = Factory(:article, :state => 'withdrawn', :published_at => '2010-01-01')
      get :index, :search => {:state => 'withdrawn'}
      expect(assigns(:articles)).to eq([article])
      expect(response).to render_template('index')
      expect(response).to be_success
    end
  
    it 'should restrict to withdrawn articles' do
      article = Factory(:article, :state => 'withdrawn', :published_at => '2010-01-01')
      get :index, :search => {:state => 'withdrawn'}
      expect(assigns(:articles)).to eq([article])
      expect(response).to render_template('index')
      expect(response).to be_success
    end

    it 'should restrict to published articles' do
      article = Factory(:article, :state => 'published', :published_at => '2010-01-01')
      get :index, :search => {:state => 'published'}
      expect(response).to render_template('index')
      expect(response).to be_success
    end

    it 'should fallback to default behavior' do
      article = Factory(:article, :state => 'draft')
      get :index, :search => {:state => '3vI1 1337 h4x0r'}
      expect(response).to render_template('index')
      expect(assigns(:articles)).not_to eq([article])
      expect(response).to be_success
    end

  end

  shared_examples_for 'autosave action' do
    describe "first time for a new article" do
      it 'should save new article with draft status and no parent article' do
        Factory(:none)
        expect {
          expect {
            post :autosave, :article => {:allow_comments => '1',
              :body_and_extended => 'my draft in autosave',
              :keywords => 'mientag',
              :permalink => 'big-post',
              :title => 'big post',
              :text_filter => 'none',
              :published => '1',
              :published_at => 'December 23, 2009 03:20 PM'}
          }.to change { Article.count }
        }.to change { Tag.count }
        result = Article.last
        expect(result.body).to eq('my draft in autosave')
        expect(result.title).to eq('big post')
        expect(result.permalink).to eq('big-post')
        expect(result.parent_id).to be_nil
        expect(result.redirects.count).to eq(0)
      end
    end

    describe "second time for a new article" do
      it 'should save the same article with draft status and no parent article' do
        draft = Factory(:article, :published => false, :state => 'draft')
        expect {
          post :autosave, :article => {
            :id => draft.id,
            :body_and_extended => 'new body' }
        }.not_to change { Article.count }
        result = Article.find(draft.id)
        expect(result.body).to eq('new body')
        expect(result.parent_id).to be_nil
        expect(result.redirects.count).to eq(0)
      end
    end

    describe "for a published article" do
      before :each do
        @article = Factory(:article)
        @data = {:allow_comments => @article.allow_comments,
          :body_and_extended => 'my draft in autosave',
          :keywords => '',
          :permalink => @article.permalink,
          :title => @article.title,
          :text_filter => @article.text_filter,
          :published => '1',
          :published_at => 'December 23, 2009 03:20 PM'}
      end

      it 'should create a draft article with proper attributes and existing article as a parent' do
        expect {
          post :autosave, :id => @article.id, :article => @data
        }.to change { Article.count }
        result = Article.last
        expect(result.body).to eq('my draft in autosave')
        expect(result.title).to eq(@article.title)
        expect(result.permalink).to eq(@article.permalink)
        expect(result.parent_id).to eq(@article.id)
        expect(result.redirects.count).to eq(0)
      end

      it 'should not create another draft article with parent_id if article has already a draft associated' do
        # Clean up any existing drafts for this article first
        Article.where(parent_id: @article.id).delete_all
        # Create draft using factory to avoid ID conflicts
        draft = Factory(:article, :state => 'draft', :parent_id => @article.id, :user => @user)
        expect {
          post :autosave, :id => @article.id, :article => @data
        }.not_to change { Article.count }
        expect(Article.where(parent_id: @article.id).last.parent_id).to eq(@article.id)
      end

      it 'should create a draft with the same permalink even if the title has changed' do
        @data[:title] = @article.title + " more stuff"
        expect {
          post :autosave, :id => @article.id, :article => @data
        }.to change { Article.count }
        result = Article.last
        expect(result.parent_id).to eq(@article.id)
        expect(result.permalink).to eq(@article.permalink)
        expect(result.redirects.count).to eq(0)
      end
    end

    describe "with an unrelated draft in the database" do
      before do
        @draft = Factory(:article, :state => 'draft')
      end

      it "leaves the original draft in existence" do
        post :autosave, 'article' => {}
        expect(assigns(:article).id).not_to eq(@draft.id)
        expect(Article.find(@draft.id)).not_to be_nil
      end
    end
  end

  describe 'insert_editor action' do

    before do
      Factory(:blog)
      @user = Factory(:user, :profile => Factory(:profile_admin, :label => Profile::ADMIN))
      request.session = { :user_id => @user.id }
    end

    it 'should render _markdown_editor for any editor param' do
      get(:insert_editor, :editor => 'simple')
      expect(response).to render_template('_markdown_editor')
    end

    it 'should render _markdown_editor for visual param' do
      get(:insert_editor, :editor => 'visual')
      expect(response).to render_template('_markdown_editor')
    end

    it 'should render _markdown_editor even if editor param is set to unknown editor' do
      get(:insert_editor, :editor => 'unknown')
      expect(response).to render_template('_markdown_editor')
    end
  end


  shared_examples_for 'new action' do

    describe 'GET' do
      it "renders the 'new' template" do
        get :new
        expect(response).to render_template('new')
        expect(assigns(:article)).not_to be_nil
        expect(assigns(:article).redirects.count).to eq(0)
      end

      it "correctly converts multi-word tags" do
        a = Factory(:article, :keywords => '"foo bar", baz')
        get :new, :id => a.id
        expect(response).to have_selector("input[id=article_keywords][value='baz, \"foo bar\"']")
      end

    end

    def base_article(options={})
      { :title => "posted via tests!",
        :body => "A good body",
        :allow_comments => '1',
        :allow_pings => '1' }.merge(options)
    end

    it 'should create article with no comments' do
      post(:new, 'article' => base_article({:allow_comments => '0'}),
                 'categories' => [Factory(:category).id])
      expect(assigns(:article)).not_to be_allow_comments
      expect(assigns(:article)).to be_allow_pings
      expect(assigns(:article)).to be_published
    end

    it 'should create a published article with a redirect' do
      post(:new, 'article' => base_article)
      expect(assigns(:article).redirects.count).to eq(1)
    end

    it 'should create a draft article without a redirect' do
      post(:new, 'article' => base_article({:state => 'draft'}))
      expect(assigns(:article).redirects.count).to eq(0)
    end

    it 'should create an unpublished article without a redirect' do
      post(:new, 'article' => base_article({:published => false}))
      expect(assigns(:article).redirects.count).to eq(0)
    end

    it 'should create an article published in the future without a redirect' do
      post(:new, 'article' => base_article({:published_at => (Time.now + 1.hour).to_s}))
      expect(assigns(:article).redirects.count).to eq(0)
    end

    it 'should create article with no pings' do
      post(:new, 'article' => {:allow_pings => '0', 'title' => 'my Title'}, 'categories' => [Factory(:category).id])
      expect(assigns(:article)).to be_allow_comments
      expect(assigns(:article)).not_to be_allow_pings
      expect(assigns(:article)).to be_published
    end

    it 'should create an article linked to the current user' do
      post :new, 'article' => base_article
      new_article = Article.last
      expect(new_article.user).to eq(@user)
    end

    it 'should create new published article' do
      expect(Article.count).to eq(1)
      post :new, 'article' => base_article
      expect(Article.count).to eq(2)
    end

    it 'should redirect to index' do
      post :new, 'article' => base_article
      expect(response).to redirect_to(action: 'index')
    end

    it 'should send notifications on create' do
      begin
        u = Factory(:user, :notify_via_email => true, :notify_on_new_articles => true)
        u.save!
        ActionMailer::Base.perform_deliveries = true
        ActionMailer::Base.deliveries = []
        emails = ActionMailer::Base.deliveries

        post :new, 'article' => base_article

        expect(emails.size).to eq(1)
        expect(emails.first.to[0]).to eq(u.email)
      ensure
        ActionMailer::Base.perform_deliveries = false
      end
    end

    it 'should create an article in a category' do
      category = Factory(:category)
      post :new, 'article' => base_article, 'categories' => [category.id]
      new_article = Article.last
      expect(new_article.categories).to eq([category])
    end

    it 'should create an article with tags' do
      post :new, 'article' => base_article(:keywords => "foo bar")
      new_article = Article.last
      expect(new_article.tags.size).to eq(2)
    end

    it 'should create article in future' do
      expect {
        post(:new,
             :article =>  base_article(:published_at => (Time.now + 1.hour).to_s) )
        expect(response).to redirect_to(action: 'index')
        expect(assigns(:article)).not_to be_published
      }.not_to change { Article.published.count }
      expect(Trigger.count).to eq(1)
      expect(assigns(:article).redirects.count).to eq(0)
    end

    it "should correctly interpret time zone in :published_at" do
      post :new, 'article' => base_article(:published_at => "February 17, 2011 08:47 PM GMT+0100 (CET)")
      new_article = Article.last
      expect(new_article.published_at).to eq(Time.utc(2011, 2, 17, 19, 47))
    end

    it 'should respect "GMT+0000 (UTC)" in :published_at' do
      post :new, 'article' => base_article(:published_at => 'August 23, 2011 08:40 PM GMT+0000 (UTC)')
      new_article = Article.last
      expect(new_article.published_at).to eq(Time.utc(2011, 8, 23, 20, 40))
    end

    it 'should create a filtered article' do
      Article.delete_all
      body = "body via *markdown*"
      extended="*foo*"
      post :new, 'article' => { :title => "another test", :body => body, :extended => extended}
      expect(response).to redirect_to(action: 'index')
      new_article = Article.order("created_at DESC").first
      expect(new_article.body).to eq(body)
      expect(new_article.extended).to eq(extended)
      expect(new_article.text_filter.name).to eq("markdown")
      expect(new_article.html(:body).strip).to eq("<p>body via <em>markdown</em></p>")
      expect(new_article.html(:extended).strip).to eq("<p><em>foo</em></p>")
    end

    describe "publishing a published article with an autosaved draft" do
      before do
        @orig = Factory(:article)
        @draft = Factory(:article, :parent_id => @orig.id, :state => 'draft', :published => false)
        post(:new,
             :id => @orig.id,
             :article => {:id => @draft.id, :body => 'update'})
      end

      it "updates the original" do
        assert_raises ActiveRecord::RecordNotFound do
          Article.find(@draft.id)
        end
      end

      it "deletes the draft" do
        expect(Article.find(@orig.id).body).to eq('update')
      end
    end

    describe "publishing a draft copy of a published article" do
      before do
        @orig = Factory(:article)
        @draft = Factory(:article, :parent_id => @orig.id, :state => 'draft', :published => false)
        post(:new,
             :id => @draft.id,
             :article => {:id => @draft.id, :body => 'update'})
      end

      it "updates the original" do
        assert_raises ActiveRecord::RecordNotFound do
          Article.find(@draft.id)
        end
      end

      it "deletes the draft" do
        expect(Article.find(@orig.id).body).to eq('update')
      end
    end

    describe "saving a published article as draft" do
      before do
        @orig = Factory(:article)
        post(:new,
             :id => @orig.id,
             :article => {:title => @orig.title, :draft => 'draft',
               :body => 'update' })
      end

      it "leaves the original published" do
        @orig.reload
        expect(@orig.published).to eq(true)
      end

      it "leaves the original as is" do
        @orig.reload
        expect(@orig.body).not_to eq('update')
      end

      it "redirects to the index" do
        expect(response).to redirect_to(:action => 'index')
      end

      it "creates a draft" do
        draft = Article.child_of(@orig.id).first
        expect(draft.parent_id).to eq(@orig.id)
        expect(draft).not_to be_published
      end
    end

    describe "with an unrelated draft in the database" do
      before do
        @draft = Factory(:article, :state => 'draft')
      end

      describe "saving new article as draft" do
        it "leaves the original draft in existence" do
          post(
            :new,
            'article' => base_article({:draft => 'save as draft'}))
          expect(assigns(:article).id).not_to eq(@draft.id)
          expect(Article.find(@draft.id)).not_to be_nil
        end
      end
    end
  end

  shared_examples_for 'destroy action' do

    it 'should_not destroy article by get' do
      expect {
        art_id = @article.id
        expect(Article.find(art_id)).not_to be_nil

        get :destroy, 'id' => art_id
        expect(response).to be_success
      }.not_to change { Article.count }
    end

    it 'should destroy article by post' do
      expect {
        art_id = @article.id
        post :destroy, 'id' => art_id
        expect(response).to redirect_to(:action => 'index')

        expect {
          article = Article.find(art_id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      }.to change { Article.count }.by(-1)
    end

  end


  describe 'with admin connection' do

    before do
      Factory(:blog)
      #TODO delete this after remove fixture
      Profile.delete_all
      @user = Factory(:user, :text_filter => Factory(:markdown), :profile => Factory(:profile_admin, :label => Profile::ADMIN))
      @user.editor = 'simple'
      @user.save
      @article = Factory(:article)
      request.session = { :user_id => @user.id }
    end

    it_should_behave_like 'index action'
    it_should_behave_like 'new action'
    it_should_behave_like 'destroy action'
    it_should_behave_like 'autosave action'

    describe 'edit action' do

      it 'should edit article' do
        get :edit, 'id' => @article.id
        expect(response).to render_template('new')
        expect(assigns(:article)).not_to be_nil
        expect(assigns(:article)).to be_valid
        expect(response.body).to include('body')
        expect(response.body).to include('extended content')
      end

      it 'should update article by edit action' do
        begin
          ActionMailer::Base.perform_deliveries = true
          emails = ActionMailer::Base.deliveries
          emails.clear

          art_id = @article.id

          body = "another *textile* test"
          post :edit, 'id' => art_id, 'article' => {:body => body, :text_filter => 'textile'}
          expect(response).to redirect_to(action: 'index')

          article = @article.reload
          expect(article.text_filter.name).to eq("textile")
          expect(body).to eq(article.body)

          expect(emails.size).to eq(0)
        ensure
          ActionMailer::Base.perform_deliveries = false
        end
      end

      it 'should allow updating body_and_extended' do
        article = @article
        post :edit, 'id' => article.id, 'article' => {
          'body_and_extended' => 'foo<!--more-->bar<!--more-->baz'
        }
        expect(response).to be_redirect
        article.reload
        expect(article.body).to eq('foo')
        expect(article.extended).to eq('bar<!--more-->baz')
      end

      it 'should delete draft about this article if update' do
        article = @article
        # Clean up any existing drafts first
        Article.where(parent_id: article.id).delete_all
        # Create draft using factory to avoid ID conflicts
        draft = Factory(:article, :state => 'draft', :parent_id => article.id, :user => @user)
        expect {
          post :edit, 'id' => article.id, 'article' => { 'title' => 'new'}
        }.to change { Article.count }.by(-1)
        expect(Article).not_to be_exists({:id => draft.id})
      end

      it 'should delete all draft about this article if update not happen but why not' do
        article = @article
        # Clean up any existing drafts first
        Article.where(parent_id: article.id).delete_all
        # Create drafts using factory to avoid ID conflicts
        draft = Factory(:article, :state => 'draft', :parent_id => article.id, :user => @user)
        draft_2 = Factory(:article, :state => 'draft', :parent_id => article.id, :user => @user)
        expect {
          post :edit, 'id' => article.id, 'article' => { 'title' => 'new'}
        }.to change { Article.count }.by(-2)
        expect(Article).not_to be_exists({:id => draft.id})
        expect(Article).not_to be_exists({:id => draft_2.id})
      end
    end

    describe 'resource_add action' do

      it 'should add resource' do
        art_id = @article.id
        resource = Factory(:resource)
        get :resource_add, :id => art_id, :resource_id => resource.id

        expect(response).to render_template('_show_resources')
        expect(assigns(:article)).to be_valid
        expect(assigns(:resource)).to be_valid
        expect(Article.find(art_id).resources.include?(resource)).to be_truthy
        expect(assigns(:article)).not_to be_nil
        expect(assigns(:resource)).not_to be_nil
        expect(assigns(:resources)).not_to be_nil
      end

    end

    describe 'resource_remove action' do

      it 'should remove resource' do
        art_id = @article.id
        resource = Factory(:resource)
        get :resource_remove, :id => art_id, :resource_id => resource.id

        expect(response).to render_template('_show_resources')
        expect(assigns(:article)).to be_valid
        expect(assigns(:resource)).to be_valid
        expect(!Article.find(art_id).resources.include?(resource)).to be_truthy
        expect(assigns(:article)).not_to be_nil
        expect(assigns(:resource)).not_to be_nil
        expect(assigns(:resources)).not_to be_nil
      end
    end

    describe 'auto_complete_for_article_keywords action' do
      before do
        Factory(:tag, :name => 'foo', :articles => [Factory(:article)])
        Factory(:tag, :name => 'bazz', :articles => [Factory(:article)])
        Factory(:tag, :name => 'bar', :articles => [Factory(:article)])
      end

      it 'should return foo for keywords fo' do
        get :auto_complete_for_article_keywords, :article => {:keywords => 'fo'}
        expect(response).to be_success
        expect(response.body).to eq('<ul class="unstyled" id="autocomplete"><li>foo</li></ul>')
      end

      it 'should return nothing for hello' do
        get :auto_complete_for_article_keywords, :article => {:keywords => 'hello'}
        expect(response).to be_success
        expect(response.body).to eq('<ul class="unstyled" id="autocomplete"></ul>')
      end

      it 'should return bar and bazz for ba keyword' do
        get :auto_complete_for_article_keywords, :article => {:keywords => 'ba'}
        expect(response).to be_success
        expect(response.body).to eq('<ul class="unstyled" id="autocomplete"><li>bar</li><li>bazz</li></ul>')
      end
    end

  end

  describe 'with publisher connection' do

    before :each do
      Factory(:blog)
      @user = Factory(:user, :text_filter => Factory(:markdown), :profile => Factory(:profile_publisher))
      @user.editor = 'simple'
      @user.save
      @article = Factory(:article, :user => @user)
      request.session = {:user_id => @user.id}
    end

    it_should_behave_like 'index action'
    it_should_behave_like 'new action'
    it_should_behave_like 'destroy action'

    describe 'edit action' do

      it "should redirect if edit article doesn't his" do
        get :edit, :id => Factory(:article, :user => Factory(:user, :login => 'another_user')).id
        expect(response).to redirect_to(:action => 'index')
      end

      it 'should edit article' do
        get :edit, 'id' => @article.id
        expect(response).to render_template('new')
        expect(assigns(:article)).not_to be_nil
        expect(assigns(:article)).to be_valid
      end

      it 'should update article by edit action' do
        begin
          ActionMailer::Base.perform_deliveries = true
          emails = ActionMailer::Base.deliveries
          emails.clear

          art_id = @article.id

          body = "another *textile* test"
          post :edit, 'id' => art_id, 'article' => {:body => body, :text_filter => 'textile'}
          expect(response).to redirect_to(:action => 'index')

          article = @article.reload
          expect(article.text_filter.name).to eq("textile")
          expect(body).to eq(article.body)

          expect(emails.size).to eq(0)
        ensure
          ActionMailer::Base.perform_deliveries = false
        end
      end
    end

    describe 'destroy action can be access' do

      it 'should redirect when want destroy article' do
        article = Factory(:article, :user => Factory(:user, :login => Factory(:user, :login => 'other_user')))
        expect {
          get :destroy, :id => article.id
          expect(response).to redirect_to(:action => 'index')
        }.not_to change { Article.count }
      end

    end
  end
end
