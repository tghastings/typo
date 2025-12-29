require 'spec_helper'

describe TagsController, "/index" do
  render_views

  before do
    Factory(:blog)
    Factory(:tag).articles << Factory(:article)
  end

  describe "normally" do
    before do
      get 'index'
    end

    specify { expect(response).to be_success }
    specify { expect(response).to render_template('articles/groupings') }
    specify { expect(assigns(:groupings)).not_to be_empty }
    specify { expect(response.body).to have_selector('ul.tags[id="taglist"]') }
  end

  describe "if :index template exists" do
    it "should render :index", pending: "Stubbing #template_exists is not enough to fool Rails" do
      controller.stub!(:template_exists?) \
        .and_return(true)

      get 'index'
      expect(response).to render_template(:index)
    end
  end
end

describe TagsController, 'showing a single tag' do
  before do
    Factory(:blog)
    @tag = Factory(:tag, :name => 'Foo')
  end

  def do_get
    get 'show', :id => 'foo'
  end

  describe "with some articles" do
    before do
      @articles = 2.times.map { Factory(:article) }
      @tag.articles << @articles
    end

    it 'should be successful' do
      do_get()
      expect(response).to be_success
    end

    it 'should retrieve the correct set of articles' do
      do_get
      expect(assigns[:articles].map(&:id).sort).to eq(@articles.map(&:id).sort)
    end

    it 'should render :show by default', pending: "Stubbing #template_exists is not enough to fool Rails" do
      controller.stub!(:template_exists?) \
        .and_return(true)
      do_get
      expect(response).to render_template(:show)
    end

    it 'should fall back to rendering articles/index' do
      controller.stub!(:template_exists?) \
        .and_return(false)
      do_get
      expect(response).to render_template('articles/index')
    end

    it 'should set the page title to "Tag foo"' do
      do_get
      expect(assigns[:page_title]).to eq('Tag: foo | test blog ')
    end

    it 'should render the atom feed for /articles/tag/foo.atom' do
      get 'show', :id => 'foo', :format => 'atom'
      expect(response).to render_template('articles/index_atom_feed')
      # No layout should be rendered for feeds
    end

    it 'should render the rss feed for /articles/tag/foo.rss' do
      get 'show', :id => 'foo', :format => 'rss'
      expect(response).to render_template('articles/index_rss_feed')
      # No layout should be rendered for feeds
    end
  end

  describe "without articles" do
    # TODO: Perhaps we can show something like 'Nothing tagged with this tag'?
    it 'should redirect to main page' do
      do_get

      expect(response.status).to eq(301)
      expect(response).to redirect_to(root_path)
    end
  end
end

describe TagsController, 'showing tag "foo"' do
  render_views

  before(:each) do
    Factory(:blog)
    #TODO need to add default article into tag_factory build to remove this :articles =>...
    foo = Factory(:tag, :name => 'foo', :articles => [Factory(:article)])
    get 'show', :id => 'foo'
  end

  it 'should have good rss feed link in head' do
    expect(response).to have_selector('head>link[href="http://myblog.net/tag/foo.rss"][rel=alternate][type="application/rss+xml"][title=RSS]')
  end

  it 'should have good atom feed link in head' do
    expect(response).to have_selector('head>link[href="http://myblog.net/tag/foo.atom"][rel=alternate][type="application/atom+xml"][title=Atom]')
  end
  
  it 'should have a canonical URL' do
    expect(response).to have_selector('head>link[href="http://myblog.net/tag/foo/"]')
  end
end

describe TagsController, "showing a non-existant tag" do
  # TODO: Perhaps we can show something like 'Nothing tagged with this tag'?
  it 'should redirect to main page' do
    Factory(:blog)
    get 'show', :id => 'thistagdoesnotexist'

    expect(response.status).to eq(301)
    expect(response).to redirect_to(root_path)
  end
end

describe TagsController, "password protected article" do
  render_views

  it 'article in tag should be password protected' do
    Factory(:blog)
    #TODO need to add default article into tag_factory build to remove this :articles =>...
    a = Factory(:article, :password => 'password')
    foo = Factory(:tag, :name => 'foo', :articles => [a])
    get 'show', :id => 'foo'
    expect(response.body).to have_selector("input#article_password")
  end
end

describe TagsController, "SEO Options" do
  render_views
  
  before(:each) do 
    @blog = Factory(:blog)
    @a = Factory(:article)
    @foo = Factory(:tag, :name => 'foo', :articles => [@a])
  end
  
  it 'should have rel nofollow' do
    @blog.unindex_tags = true
    @blog.save
    
    get 'show', :id => 'foo'
    expect(response).to have_selector('head>meta[content="noindex, follow"]')
  end

  it 'should not have rel nofollow' do
    @blog.unindex_tags = false
    @blog.save
    
    get 'show', :id => 'foo'
    expect(response).not_to have_selector('head>meta[content="noindex, follow"]')
  end
  # meta_keywords
  
  it 'should not have meta keywords with deactivated option and no blog keywords' do
    @blog.use_meta_keyword = false
    @blog.save
    get 'show', :id => 'foo'
    expect(response).not_to have_selector('head>meta[name="keywords"]')
  end

  it 'should not have meta keywords with deactivated option and blog keywords' do
    @blog.use_meta_keyword = false
    @blog.meta_keywords = "foo, bar, some, keyword"
    @blog.save
    get 'show', :id => 'foo'
    expect(response).not_to have_selector('head>meta[name="keywords"]')
  end

  it 'should not have meta keywords with activated option and no blog keywords' do
    @blog.use_meta_keyword = true
    @blog.save
    get 'show', :id => 'foo'
    expect(response).not_to have_selector('head>meta[name="keywords"]')
  end

  it 'should have meta keywords with activated option and blog keywords' do
    @blog.use_meta_keyword = true
    @blog.meta_keywords = "foo, bar, some, keyword"
    @blog.save
    get 'show', :id => 'foo'
    expect(response).to have_selector('head>meta[name="keywords"]')
  end

end
