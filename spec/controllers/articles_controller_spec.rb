# frozen_string_literal: true

require 'spec_helper'

describe ArticlesController do
  render_views

  before(:each) do
    # TODO: Need to reduce user, but allow to remove user fixture...
    Factory(:user,
            login: 'henri',
            password: 'whatever',
            name: 'Henri',
            email: 'henri@example.com',
            settings: { notify_watch_my_articles: false, editor: 'simple' },
            text_filter: Factory(:markdown),
            profile: Factory(:profile_admin, label: Profile::ADMIN),
            notify_via_email: false,
            notify_on_new_articles: false,
            notify_on_comments: false,
            state: 'active')
    Factory(:blog, custom_tracking_field: '<script src="foo.js" type="text/javascript"></script>')
  end

  it 'should redirect category to /categories' do
    get 'category'
    expect(response).to redirect_to(categories_path)
  end

  it 'should redirect tag to /tags' do
    get 'tag'
    expect(response).to redirect_to(tags_path)
  end

  describe 'index action' do
    before :each do
      Factory.create(:article)
      get 'index'
    end

    it 'should be render template index' do
      expect(response).to render_template(:index)
    end

    it 'should show some articles' do
      expect(assigns[:articles]).not_to be_empty
    end

    it 'should have good link feed rss' do
      expect(response).to have_selector('head>link[href="http://myblog.net/articles.rss"]')
    end

    it 'should have good link feed atom' do
      expect(response).to have_selector('head>link[href="http://myblog.net/articles.atom"]')
    end

    it 'should have a canonical url' do
      expect(response).to have_selector('head>link[href="http://myblog.net/"]')
    end

    it 'should have googd title' do
      expect(response).to have_selector('title', content: 'test blog | test subtitles')
    end

    it 'should have a custom tracking field' do
      expect(response).to have_selector('head>script[src="foo.js"]')
    end
  end

  describe '#search action' do
    before :each do
      Factory(:article,
              body: "in markdown format\n\n * we\n * use\n [ok](http://blog.ok.com) to define a link",
              text_filter: Factory(:markdown))
      Factory(:article, body: 'xyz')
    end

    describe 'a valid search' do
      before :each do
        get 'search', q: 'a'
      end

      it 'should render template search' do
        expect(response).to render_template(:search)
      end

      it 'should assigns articles' do
        expect(assigns[:articles]).not_to be_nil
      end

      it 'should have good feed rss link' do
        expect(response).to have_selector('head>link[href="http://myblog.net/search/a.rss"]')
      end

      it 'should have good feed atom link' do
        expect(response).to have_selector('head>link[href="http://myblog.net/search/a.atom"]')
      end

      it 'should have a canonical url' do
        expect(response).to have_selector('head>link[href="http://myblog.net/search/a"]')
      end

      it 'should have a good title' do
        expect(response).to have_selector('title', content: 'Results for a | test blog')
      end

      it 'should have content markdown interpret and without html tag' do
        expect(response.body).to include('in markdown format')
        expect(response.body).to include('we')
        expect(response.body).to include('use')
        expect(response.body).to include('ok to define a link')
      end

      it 'should have a custom tracking field' do
        expect(response).to have_selector('head>script[src="foo.js"]')
      end
    end

    it 'should render feed rss by search' do
      get 'search', q: 'a', format: 'rss'
      expect(response).to be_success
      expect(response).to render_template('index_rss_feed')
      # No layout should be rendered for feeds
      expect(response).not_to have_selector('head>script[src="foo.js"]')
    end

    it 'should render feed atom by search' do
      get 'search', q: 'a', format: 'atom'
      expect(response).to be_success
      expect(response).to render_template('index_atom_feed')
      # No layout should be rendered for feeds
      expect(response).not_to have_selector('head>script[src="foo.js"]')
    end

    it 'search with empty result' do
      get 'search', q: 'abcdefghijklmnopqrstuvwxyz'
      expect(response).to render_template('articles/error')
      expect(assigns[:articles]).to be_empty
    end
  end

  describe '#livesearch action' do
    describe 'with a query with several words' do
      before :each do
        Factory.create(:article, body: 'hello world and im herer')
        Factory.create(:article, title: 'hello', body: 'worldwide')
        Factory.create(:article)
        get :live_search, q: 'hello world'
      end

      it 'should be valid' do
        expect(assigns[:articles]).not_to be_empty
        expect(assigns[:articles].size).to eq(2)
      end

      it 'should render without layout' do
        expect(response).to render_template(layout: nil)
      end

      it 'should render template live_search' do
        expect(response).to render_template('live_search')
      end

      it 'should not have h3 tag' do
        expect(response).to have_selector('h3')
      end

      it 'should assign @search the search string' do
        expect(assigns[:search]).to be_equal(controller.params[:q])
      end
    end
  end

  it 'archives' do
    3.times { Factory(:article) }
    get 'archives'
    expect(response).to render_template(:archives)
    expect(assigns[:articles]).not_to be_nil
    expect(assigns[:articles]).not_to be_empty

    expect(response).to have_selector('head>link[href="http://test.host/archives"]')
    expect(response).to have_selector('title', content: 'Archives for test blog')
    expect(response).to have_selector('head>script[src="foo.js"]')
  end

  describe 'index for a month' do
    before :each do
      Factory(:article, published_at: Time.utc(2004, 4, 23))
      get 'index', year: 2004, month: 4
    end

    it 'should render template index' do
      expect(response).to render_template(:index)
    end

    it 'should contain some articles' do
      expect(assigns[:articles]).not_to be_nil
      expect(assigns[:articles]).not_to be_empty
    end

    it 'should have a canonical url' do
      expect(response).to have_selector('head>link[href="http://myblog.net/2004/4/"]')
    end

    it 'should have a good title' do
      expect(response).to have_selector('title', content: 'Archives for test blog')
    end

    it 'should have a custom tracking field' do
      expect(response).to have_selector('head>script[src="foo.js"]')
    end
  end
end

describe ArticlesController, 'nosettings' do
  before(:each) do
    Blog.delete_all
    @blog = Blog.new.save
  end

  it 'redirects to setup' do
    get 'index'
    expect(response).to redirect_to(controller: 'setup', action: 'index')
  end
end

describe ArticlesController, 'nousers' do
  before(:each) do
    Factory(:blog)
    User.stub!(:count).and_return(0)
    @user = mock('user',
                 login: 'testuser',
                 email: 'test@example.com',
                 name: 'Test User',
                 id: 1)
    @user.stub!(:reload).and_return(@user)
    User.stub!(:new).and_return(@user)
  end

  it 'redirects to signup' do
    get 'index'
    expect(response).to redirect_to(controller: 'accounts', action: 'signup')
  end
end

describe ArticlesController, 'feeds' do
  before(:each) do
    Factory(:blog)
    @article1 = Factory.create(:article,
                               created_at: Time.now - 1.day)
    Factory.create(:trackback, article: @article1, published_at: Time.now - 1.day,
                               published: true)
    @article2 = Factory.create(:article,
                               created_at: '2004-04-01 12:00:00',
                               published_at: '2004-04-01 12:00:00',
                               updated_at: '2004-04-01 12:00:00')
  end

  specify '/articles.atom => an atom feed' do
    get 'index', format: 'atom'
    expect(response).to be_success
    expect(response).to render_template('index_atom_feed')
    expect(assigns(:articles)).to eq([@article1, @article2])
    # No layout should be rendered for feeds
  end

  specify '/articles.rss => an RSS 2.0 feed' do
    get 'index', format: 'rss'
    expect(response).to be_success
    expect(response).to render_template('index_rss_feed')
    expect(assigns(:articles)).to eq([@article1, @article2])
    # No layout should be rendered for feeds
  end

  specify 'atom feed for archive should be valid' do
    get 'index', year: 2004, month: 4, format: 'atom'
    expect(response).to render_template('index_atom_feed')
    expect(assigns(:articles)).to eq([@article2])
    # No layout should be rendered for feeds
  end

  specify 'RSS feed for archive should be valid' do
    get 'index', year: 2004, month: 4, format: 'rss'
    expect(response).to render_template('index_rss_feed')
    expect(assigns(:articles)).to eq([@article2])
    # No layout should be rendered for feeds
  end
end

describe ArticlesController, 'the index' do
  before(:each) do
    Factory(:blog)
    Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
    Factory(:article)
  end

  it 'should ignore the HTTP Accept: header' do
    request.env['HTTP_ACCEPT'] = 'application/atom+xml'
    get 'index'
    expect(response).to render_template('index')
  end
end

describe ArticlesController, 'previewing' do
  render_views
  before(:each) { @blog = Factory(:blog) }

  describe 'with non logged user' do
    before :each do
      @request.session = {}
      get :preview, id: Factory(:article).id
    end

    it 'should redirect to login' do
      expect(response).to redirect_to(controller: 'accounts', action: 'login')
    end
  end

  describe 'with logged user' do
    before :each do
      # TODO: Delete after removing fixtures
      Profile.delete_all
      henri = Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
      @request.session = { user_id: henri.id }
      @article = Factory(:article)
    end

    with_each_theme do |theme, view_path|
      it "should render template #{view_path}/articles/read" do
        @blog.theme = theme if theme
        get :preview, id: @article.id
        expect(response).to render_template('articles/read')
      end
    end

    it 'should assigns article define with id' do
      get :preview, id: @article.id
      expect(assigns[:article]).to eq(@article)
    end

    it 'should assigns last article with id like parent_id' do
      draft = Factory(:article, parent_id: @article.id)
      get :preview, id: @article.id
      expect(assigns[:article]).to eq(draft)
    end
  end
end

describe ArticlesController, 'redirecting' do
  describe 'with explicit redirects' do
    it 'should redirect from known URL' do
      # TODO: Need to reduce user, but allow to remove user fixture...
      Factory(:user,
              login: 'henri',
              password: 'whatever',
              name: 'Henri',
              email: 'henri@example.com',
              settings: { notify_watch_my_articles: false, editor: 'simple' },
              text_filter: Factory(:markdown),
              profile: Factory(:profile_admin, label: Profile::ADMIN),
              notify_via_email: false,
              notify_on_new_articles: false,
              notify_on_comments: false,
              state: 'active')
      Factory(:blog)
      Factory(:redirect)
      get :redirect, from: 'foo/bar'
      expect(response).to have_http_status(301)
      expect(response).to redirect_to('http://myblog.net/someplace/else')
    end

    it 'should not redirect from unknown URL' do
      # TODO: Need to reduce user, but allow to remove user fixture...
      Factory(:user,
              login: 'henri',
              password: 'whatever',
              name: 'Henri',
              email: 'henri@example.com',
              settings: { notify_watch_my_articles: false, editor: 'simple' },
              text_filter: Factory(:markdown),
              profile: Factory(:profile_admin, label: Profile::ADMIN),
              notify_via_email: false,
              notify_on_new_articles: false,
              notify_on_comments: false,
              state: 'active')
      Factory(:blog)
      Factory(:redirect)
      get :redirect, from: 'something/that/isnt/there'
      expect(response).to have_http_status(404)
    end

    # FIXME: Due to the changes in Rails 3 (no relative_url_root), this
    # does not work anymore when the accessed URL does not match the blog's
    # base_url at least partly. Do we still want to allow acces to the blog
    # through non-standard URLs? What was the original purpose of these
    # redirects?
    describe 'and non-empty relative_url_root' do
      before do
        Factory(:blog, base_url: 'http://test.host/blog')
        # TODO: Need to reduce user, but allow to remove user fixture...
        Factory(:user,
                login: 'henri',
                password: 'whatever',
                name: 'Henri',
                email: 'henri@example.com',
                settings: { notify_watch_my_articles: false, editor: 'simple' },
                text_filter: Factory(:markdown),
                profile: Factory(:profile_admin, label: Profile::ADMIN),
                notify_via_email: false,
                notify_on_new_articles: false,
                notify_on_comments: false,
                state: 'active')

        # XXX: The following has no effect anymore.
        # request.env["SCRIPT_NAME"] = "/blog"
      end

      it 'should redirect' do
        Factory(:redirect, from_path: 'foo/bar', to_path: '/someplace/else')
        get :redirect, from: 'foo/bar'
        expect(response).to have_http_status(301)
        expect(response).to redirect_to('http://test.host/blog/someplace/else')
      end

      it 'should redirect if to_path includes relative_url_root' do
        Factory(:redirect, from_path: 'bar/foo', to_path: '/blog/someplace/else')
        get :redirect, from: 'bar/foo'
        expect(response).to have_http_status(301)
        expect(response).to redirect_to('http://test.host/blog/someplace/else')
      end

      it 'should ignore the blog base_url if the to_path is a full uri' do
        Factory(:redirect, from_path: 'foo', to_path: 'http://some.where/else')
        get :redirect, from: 'foo'
        expect(response).to have_http_status(301)
        expect(response).to redirect_to('http://some.where/else')
      end
    end
  end

  it 'should get good article with utf8 slug' do
    Factory(:blog)
    utf8article = Factory.create(:utf8article, permalink: 'ルビー',
                                               published_at: Time.utc(2004, 6, 2))
    get :redirect, from: '2004/06/02/ルビー'
    expect(assigns(:article)).to eq(utf8article)
  end

  # NOTE: This is needed because Rails over-unescapes glob parameters.
  it 'should get good article with pre-escaped utf8 slug using unescaped slug' do
    Factory(:blog)
    utf8article = Factory.create(:utf8article, permalink: '%E3%83%AB%E3%83%93%E3%83%BC',
                                               published_at: Time.utc(2004, 6, 2))
    get :redirect, from: '2004/06/02/ルビー'
    expect(assigns(:article)).to eq(utf8article)
  end

  describe 'accessing old-style URL with "articles" as the first part' do
    it 'should redirect to article' do
      Factory(:blog)
      Factory(:article, permalink: 'second-blog-article',
                        published_at: '2004-04-01 02:00:00',
                        updated_at: '2004-04-01 02:00:00',
                        created_at: '2004-04-01 02:00:00')
      get :redirect, from: 'articles/2004/04/01/second-blog-article'
      expect(response).to have_http_status(301)
      expect(response).to redirect_to('http://myblog.net/2004/04/01/second-blog-article')
    end

    it 'should redirect to article with url_root' do
      Factory(:blog, base_url: 'http://test.host/blog')
      Factory(:article, permalink: 'second-blog-article',
                        published_at: '2004-04-01 02:00:00',
                        updated_at: '2004-04-01 02:00:00',
                        created_at: '2004-04-01 02:00:00')
      get :redirect, from: 'articles/2004/04/01/second-blog-article'
      expect(response).to have_http_status(301)
      expect(response).to redirect_to('http://test.host/blog/2004/04/01/second-blog-article')
    end

    it 'should redirect to article with articles in url_root' do
      Factory(:blog, base_url: 'http://test.host/aaa/articles/bbb')
      Factory(:article, permalink: 'second-blog-article',
                        published_at: '2004-04-01 02:00:00',
                        updated_at: '2004-04-01 02:00:00',
                        created_at: '2004-04-01 02:00:00')
      get :redirect, from: 'articles/2004/04/01/second-blog-article'
      expect(response).to have_http_status(301)
      expect(response).to redirect_to('http://test.host/aaa/articles/bbb/2004/04/01/second-blog-article')
    end
  end

  describe 'with permalink_format like %title%.html' do
    before(:each) do
      Factory(:blog, permalink_format: '/%title%.html')

      @article = Factory(:article, permalink: 'second-blog-article',
                                   published_at: '2004-04-01 02:00:00',
                                   updated_at: '2004-04-01 02:00:00',
                                   created_at: '2004-04-01 02:00:00')
    end

    describe 'accessing various non-matching URLs' do
      it "should not find '.htmlsecond-blog-article'" do
        get :redirect, from: ".html#{@article.permalink}"
        expect(response).to have_http_status(404)
      end

      it "should not find 'second-blog-article.html.html'" do
        get :redirect, from: "#{@article.permalink}.html.html"
        expect(response).to have_http_status(404)
      end

      it "should not find 'second-blog-article.html/foo'" do
        get :redirect, from: "#{@article.permalink}.html/foo"
        expect(response).to have_http_status(404)
      end
    end

    describe 'accessing legacy URLs' do
      it 'should redirect from default URL format' do
        get :redirect, from: '2004/04/01/second-blog-article'
        expect(response).to have_http_status(301)
        expect(response).to redirect_to('http://myblog.net/second-blog-article.html')
      end

      it 'should redirect from old-style URL format with "articles" part' do
        get :redirect, from: 'articles/2004/04/01/second-blog-article'
        expect(response).to have_http_status(301)
        expect(response).to redirect_to('http://myblog.net/second-blog-article.html')
      end
    end

    describe 'accessing an article' do
      before(:each) do
        get :redirect, from: "#{@article.permalink}.html"
      end

      it 'should render template read to article' do
        expect(response).to render_template('articles/read')
      end

      it 'should assign article1 to @article' do
        expect(assigns(:article)).to eq(@article)
      end

      describe 'the resulting page' do
        render_views

        it 'should have good rss feed link' do
          expect(response).to have_selector("head>link[href=\"http://myblog.net/#{@article.permalink}.html.rss\"]")
        end

        it 'should have good atom feed link' do
          expect(response).to have_selector("head>link[href=\"http://myblog.net/#{@article.permalink}.html.atom\"]")
        end

        it 'should have a canonical url' do
          expect(response).to have_selector("head>link[href='http://myblog.net/#{@article.permalink}.html']")
        end

        it 'should have a good title' do
          expect(response).to have_selector('title', content: 'A big article | test blog')
        end
      end
    end

    describe 'rendering as atom feed' do
      before(:each) do
        @trackback1 = Factory.create(:trackback, article: @article, published_at: Time.now - 1.day,
                                                 published: true)
        get :redirect, from: "#{@article.permalink}.html.atom"
      end

      it 'should render feedback atom feed' do
        expect(assigns(:feedback)).to eq([@trackback1])
        expect(response).to render_template('feedback_atom_feed')
        # No layout should be rendered for feeds
      end
    end

    describe 'rendering as rss feed' do
      before(:each) do
        @trackback1 = Factory.create(:trackback, article: @article, published_at: Time.now - 1.day,
                                                 published: true)
        get :redirect, from: "#{@article.permalink}.html.rss"
      end

      it 'should render rss20 partial' do
        expect(assigns(:feedback)).to eq([@trackback1])
        expect(response).to render_template('feedback_rss_feed')
        # No layout should be rendered for feeds
      end
    end
  end

  describe 'with a format containing a fixed component' do
    before(:each) do
      Factory(:blog, permalink_format: '/foo/%title%')

      @article = Factory(:article)
    end

    it 'should find the article if the url matches all components' do
      get :redirect, from: "foo/#{@article.permalink}"
      expect(response).to be_successful
    end

    it 'should not find the article if the url does not match the fixed component' do
      get :redirect, from: "bar/#{@article.permalink}"
      expect(response).to have_http_status(404)
    end
  end

  describe 'with a custom format with several fixed parts and several variables' do
    before(:each) do
      Factory(:blog, permalink_format: '/foo/bar/%year%/%month%/%title%')

      @article = Factory(:article)
    end

    it 'should find the article if the url matches all components' do
      get :redirect, from: "foo/bar/#{@article.year_url}/#{@article.month_url}/#{@article.permalink}"
      expect(response).to be_successful
    end

    # FIXME: Documents current behavior; Blog URL format is only meant for one article shown
    it 'should not find the article if the url only matches some components' do
      get :redirect, from: "foo/bar/#{@article.year_url}/#{@article.month_url}"
      expect(response).to have_http_status(404)
    end

    # TODO: Think about allowing this, and changing find_by_params_hash to match.
  end
end

describe ArticlesController, 'password protected' do
  render_views

  before do
    Factory(:blog, permalink_format: '/%title%.html')
    @article = Factory(:article, password: 'password')
  end

  it 'article alone should be password protected' do
    get :redirect, from: "#{@article.permalink}.html"
    expect(response).to have_selector('input[id="article_password"]', count: 1)
  end

  describe '#check_password' do
    it 'shows article when given correct password' do
      post :check_password, { article: { id: @article.id, password: @article.password } }, { xhr: true }
      expect(response).not_to have_selector('input[id="article_password"]')
    end

    it 'shows password form when given incorrect password' do
      post :check_password, { article: { id: @article.id, password: 'wrong password' } }, { xhr: true }
      expect(response).to have_selector('input[id="article_password"]')
    end
  end
end

describe ArticlesController, 'assigned keywords' do
  before do
    @blog = Factory(:blog)
    # TODO: Need to reduce user, but allow to remove user fixture...
    Factory(:user,
            login: 'henri',
            password: 'whatever',
            name: 'Henri',
            email: 'henri@example.com',
            settings: { notify_watch_my_articles: false, editor: 'simple' },
            text_filter: Factory(:markdown),
            profile: Factory(:profile_admin, label: Profile::ADMIN),
            notify_via_email: false,
            notify_on_new_articles: false,
            notify_on_comments: false,
            state: 'active')
  end

  it 'article with categories should have meta keywords' do
    @blog.permalink_format = '/%title%.html'
    @blog.save
    category = Factory(:category)
    article = Factory(:article, categories: [category])
    get :redirect, from: "#{article.permalink}.html"
    expect(assigns(:keywords)).to eq(category.name)
  end

  it 'article with neither categories nor tags should not have meta keywords' do
    @blog.permalink_format = '/%title%.html'
    @blog.save
    article = Factory(:article)
    get :redirect, from: "#{article.permalink}.html"
    expect(assigns(:keywords)).to eq('')
  end

  it 'index without option and no blog keywords should not have meta keywords' do
    get 'index'
    expect(assigns(:keywords)).to eq('')
  end

  it 'index without option but with blog keywords should have meta keywords' do
    @blog.meta_keywords = 'typo, is, amazing'
    @blog.save
    get 'index'
    expect(assigns(:keywords)).to eq('typo, is, amazing')
  end
end
