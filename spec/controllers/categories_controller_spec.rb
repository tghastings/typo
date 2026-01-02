require 'spec_helper'

describe CategoriesController, "/index" do
  before do
    Factory(:blog)
    3.times {
      category = Factory(:category)
      2.times { category.articles << Factory(:article) }
    }
  end

  describe "normally" do
    before do
      controller.stub(:template_exists?).and_return false
      get 'index'
    end

    specify { expect(response).to be_success }
    specify { expect(response).to render_template('articles/groupings') }
    specify { expect(assigns(:groupings)).not_to be_empty }

    describe "when rendered" do
      render_views

      specify { expect(response.body).to have_selector('ul.categorylist') }
    end
  end

  describe "if :index template exists" do
    it "should render :index", pending: "Stubbing #template_exists is not enough to fool Rails" do
      controller.stub!(:template_exists?) \
        .and_return(true)

      do_get
      expect(response).to render_template(:index)
    end
  end
end

describe CategoriesController, '#show' do
  before do
    blog = Factory(:blog, :base_url => "http://myblog.net", :theme => "scribbish",
                      :use_canonical_url => true, :blog_name => "My Shiny Weblog!")
    Blog.stub(:default) { blog }
    Trigger.stub(:fire) { }

    category = Factory(:category, :permalink => 'personal', :name => 'Personal')
    2.times {|i| Factory(:article, :published_at => Time.now, :categories => [category]) }
    Factory(:article, :published_at => nil)
  end

  def do_get
    get 'show', :id => 'personal'
  end

  it 'should be successful' do
    do_get
    expect(response).to be_success
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
  
  it 'should render personal when template exists', pending: "Stubbing #template_exists is not enough to fool Rails" do
    controller.stub!(:template_exists?) \
      .and_return(true)
    do_get
    expect(response).to render_template('personal')
  end  

  it 'should show only published articles' do
    do_get
    expect(assigns(:articles).size).to eq(2)
  end

  it 'should set the page title to "Category Personal"' do
    do_get
    expect(assigns[:page_title]).to eq('Category: Personal | My Shiny Weblog! ')
  end

  describe "when rendered" do
    render_views
  
    it 'should have a canonical URL' do
      do_get
      expect(response).to have_selector('head>link[href="http://myblog.net/category/personal/"]')
    end
  end

  it 'should render the atom feed for /articles/category/personal.atom' do
    get 'show', :id => 'personal', :format => 'atom'
    expect(response).to render_template('articles/index_atom_feed')
    # No layout should be rendered for feeds
  end

  it 'should render the rss feed for /articles/category/personal.rss' do
    get 'show', :id => 'personal', :format => 'rss'
    expect(response).to render_template('articles/index_rss_feed')
    # No layout should be rendered for feeds
  end
end

describe CategoriesController, "#show with a non-existent category" do
  before do
    blog = stub_model(Blog, :base_url => "http://myblog.net", :theme => "scribbish",
                      :use_canonical_url => true)
    Blog.stub(:default) { blog }
    Trigger.stub(:fire) { }
  end

  it 'should raise ActiveRecord::RecordNotFound' do
    expect(Category).to receive(:find_by_permalink) \
      .with('foo').and_raise(ActiveRecord::RecordNotFound)
    expect do
      get 'show', :id => 'foo'
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end

describe CategoriesController, 'empty category life-on-mars' do
  it 'should redirect to home when the category is empty' do
    Factory(:blog)
    Factory(:category, :permalink => 'life-on-mars')
    get 'show', :id => 'life-on-mars'
    expect(response.status).to eq(301)
    expect(response).to redirect_to(root_path)
  end
end

describe CategoriesController, "password protected article" do
  render_views

  it 'should be password protected when shown in category' do
    Factory(:blog)
    cat = Factory(:category, :permalink => 'personal')
    cat.articles << Factory(:article, :password => 'my_super_pass')
    cat.save!

    get 'show', :id => 'personal'

    expect(response.body).to have_selector("input#article_password")
  end  
end

describe CategoriesController, "SEO Options" do
  render_views

  it 'category without meta keywords and activated options (use_meta_keyword ON) should not have meta keywords' do
    Factory(:blog, :use_meta_keyword => true)
    cat = Factory(:category, :permalink => 'personal')
    Factory(:article, :categories => [cat])
    get 'show', :id => 'personal'
    expect(response).not_to have_selector('head>meta[name="keywords"]')
  end

  it 'category with keywords and activated option (use_meta_keyword ON) should have meta keywords' do
    Factory(:blog, :use_meta_keyword => true)
    after_build_category_should_have_selector('head>meta[name="keywords"]')
  end

  it 'category with meta keywords and deactivated options (use_meta_keyword off) should not have meta keywords' do
    Factory(:blog, :use_meta_keyword => false)
    after_build_category_should_not_have_selector('head>meta[name="keywords"]')
  end

  it 'with unindex_categories (set ON), should have rel nofollow' do
    Factory(:blog, :unindex_categories => true)
    after_build_category_should_have_selector('head>meta[content="noindex, follow"]')
  end

  it 'without unindex_categories (set OFF), should not have rel nofollow' do
    Factory(:blog, :unindex_categories => false)
    after_build_category_should_not_have_selector('head>meta[content="noindex, follow"]')
  end

  def after_build_category_should_have_selector expected
    cat = Factory(:category, :permalink => 'personal', :keywords => "some, keywords")
    Factory(:article, :categories => [cat])
    get 'show', :id => 'personal'
    expect(response).to have_selector(expected)
  end

  def after_build_category_should_not_have_selector expected
    cat = Factory(:category, :permalink => 'personal', :keywords => "some, keywords")
    Factory(:article, :categories => [cat])
    get 'show', :id => 'personal'
    expect(response).not_to have_selector(expected)
  end
end
