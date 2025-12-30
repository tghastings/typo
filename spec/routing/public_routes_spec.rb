require 'spec_helper'

describe "Public Routes", type: :routing do
  describe "ArticlesController" do
    it "routes GET / to articles#index" do
      expect(get: "/").to route_to(controller: "articles", action: "index")
    end

    it "routes GET /page/2 to articles#index with page" do
      expect(get: "/page/2").to route_to(controller: "articles", action: "index", page: "2")
    end

    it "routes GET /articles.rss to articles#index with rss format" do
      expect(get: "/articles.rss").to route_to(controller: "articles", action: "index", format: "rss")
    end

    it "routes GET /articles.atom to articles#index with atom format" do
      expect(get: "/articles.atom").to route_to(controller: "articles", action: "index", format: "atom")
    end

    it "routes GET /archives to articles#archives" do
      expect(get: "/archives/").to route_to(controller: "articles", action: "archives")
    end

    it "routes GET /search to articles#search" do
      expect(get: "/search/").to route_to(controller: "articles", action: "search")
    end

    it "routes GET /search/query to articles#search with query" do
      expect(get: "/search/test").to route_to(controller: "articles", action: "search", q: "test")
    end

    it "routes GET /search/query.rss to articles#search with rss format" do
      expect(get: "/search/test.rss").to route_to(controller: "articles", action: "search", q: "test", format: "rss")
    end

    it "routes GET /live_search to articles#live_search" do
      expect(get: "/live_search/").to route_to(controller: "articles", action: "live_search")
    end

    it "routes GET /pages/about to articles#view_page" do
      expect(get: "/pages/about").to route_to(controller: "articles", action: "view_page", name: "about")
    end

    it "routes GET /previews to articles#preview" do
      expect(get: "/previews").to route_to(controller: "articles", action: "preview")
    end

    it "routes POST /previews to articles#preview" do
      expect(post: "/previews").to route_to(controller: "articles", action: "preview")
    end

    it "routes POST /check_password to articles#check_password" do
      expect(post: "/check_password").to route_to(controller: "articles", action: "check_password")
    end

    it "routes GET year archives" do
      expect(get: "/2024").to route_to(controller: "articles", action: "index", year: "2024")
    end

    it "routes GET year/month archives" do
      expect(get: "/2024/01").to route_to(controller: "articles", action: "index", year: "2024", month: "01")
    end
  end

  describe "CategoriesController" do
    it "routes GET /categories to categories#index" do
      expect(get: "/categories").to route_to(controller: "categories", action: "index")
    end

    it "routes GET /category/1 to categories#show" do
      expect(get: "/category/1").to route_to(controller: "categories", action: "show", id: "1")
    end

    it "routes GET /category/1/page/2 to categories#show with page" do
      expect(get: "/category/1/page/2").to route_to(controller: "categories", action: "show", id: "1", page: "2")
    end
  end

  describe "TagsController" do
    it "routes GET /tags to tags#index" do
      expect(get: "/tags").to route_to(controller: "tags", action: "index")
    end

    it "routes GET /tag/1 to tags#show" do
      expect(get: "/tag/1").to route_to(controller: "tags", action: "show", id: "1")
    end

    it "routes GET /tag/1/page/2 to tags#show with page" do
      expect(get: "/tag/1/page/2").to route_to(controller: "tags", action: "show", id: "1", page: "2")
    end

    it "routes GET /tags/page/2 to tags#index with page" do
      expect(get: "/tags/page/2").to route_to(controller: "tags", action: "index", page: "2")
    end
  end

  describe "AuthorsController" do
    it "routes GET /author/1 to authors#show" do
      expect(get: "/author/1").to route_to(controller: "authors", action: "show", id: "1")
    end

    it "routes GET /author/1.rss to authors#show with rss format" do
      expect(get: "/author/1.rss").to route_to(controller: "authors", action: "show", id: "1", format: "rss")
    end

    it "routes GET /author/1.atom to authors#show with atom format" do
      expect(get: "/author/1.atom").to route_to(controller: "authors", action: "show", id: "1", format: "atom")
    end
  end

  describe "CommentsController" do
    it "routes GET /comments to comments#index" do
      expect(get: "/comments").to route_to(controller: "comments", action: "index")
    end

    it "routes POST /comments to comments#create" do
      expect(post: "/comments").to route_to(controller: "comments", action: "create")
    end

    it "routes GET /comments/preview to comments#preview" do
      expect(get: "/comments/preview").to route_to(controller: "comments", action: "preview")
    end

    it "routes POST /comments/preview to comments#preview" do
      expect(post: "/comments/preview").to route_to(controller: "comments", action: "preview")
    end
  end

  describe "TrackbacksController" do
    it "routes GET /trackbacks to trackbacks#index" do
      expect(get: "/trackbacks").to route_to(controller: "trackbacks", action: "index")
    end

    it "routes POST /trackbacks to trackbacks#create" do
      expect(post: "/trackbacks").to route_to(controller: "trackbacks", action: "create")
    end
  end

  describe "AccountsController" do
    it "routes GET /accounts/login to accounts#login" do
      expect(get: "/accounts/login").to route_to(controller: "accounts", action: "login")
    end

    it "routes POST /accounts/login to accounts#login" do
      expect(post: "/accounts/login").to route_to(controller: "accounts", action: "login")
    end

    it "routes GET /accounts/logout to accounts#logout" do
      expect(get: "/accounts/logout").to route_to(controller: "accounts", action: "logout")
    end

    it "routes GET /accounts/recover_password to accounts#recover_password" do
      expect(get: "/accounts/recover_password").to route_to(controller: "accounts", action: "recover_password")
    end

    it "routes POST /accounts/recover_password to accounts#recover_password" do
      expect(post: "/accounts/recover_password").to route_to(controller: "accounts", action: "recover_password")
    end
  end

  describe "SetupController" do
    it "routes GET /setup to setup#index" do
      expect(get: "/setup").to route_to(controller: "setup", action: "index")
    end

    it "routes POST /setup to setup#index" do
      expect(post: "/setup").to route_to(controller: "setup", action: "index")
    end

    it "routes GET /setup/confirm to setup#confirm" do
      expect(get: "/setup/confirm").to route_to(controller: "setup", action: "confirm")
    end

    it "routes POST /setup/confirm to setup#confirm" do
      expect(post: "/setup/confirm").to route_to(controller: "setup", action: "confirm")
    end
  end

  describe "XmlController" do
    it "routes GET /xml/rsd to xml#rsd" do
      expect(get: "/xml/rsd").to route_to(controller: "xml", action: "rsd")
    end

    it "routes GET /xml/rss to xml#feed with rss" do
      expect(get: "/xml/rss").to route_to(controller: "xml", action: "feed", type: "feed", format: "rss")
    end

    it "routes GET /sitemap.xml to xml#feed with googlesitemap format" do
      expect(get: "/sitemap.xml").to route_to(controller: "xml", action: "feed", format: "googlesitemap", type: "sitemap")
    end
  end

  describe "ThemeController" do
    it "routes GET /stylesheets/theme/style.css to theme#stylesheets" do
      expect(get: "/stylesheets/theme/style.css").to route_to(controller: "theme", action: "stylesheets", filename: "style.css")
    end

    it "routes GET /javascripts/theme/main.js to theme#javascript" do
      expect(get: "/javascripts/theme/main.js").to route_to(controller: "theme", action: "javascript", filename: "main.js")
    end

    it "routes GET /images/theme/logo.png to theme#images" do
      expect(get: "/images/theme/logo.png").to route_to(controller: "theme", action: "images", filename: "logo.png")
    end
  end

  describe "BackendController" do
    # Skip these tests - BackendController uses ActionWebService which has compatibility issues
    it "routes GET /backend/xmlrpc to backend#xmlrpc", skip: "ActionWebService compatibility issue" do
      expect(get: "/backend/xmlrpc").to route_to(controller: "backend", action: "xmlrpc")
    end

    it "routes POST /backend/xmlrpc to backend#xmlrpc", skip: "ActionWebService compatibility issue" do
      expect(post: "/backend/xmlrpc").to route_to(controller: "backend", action: "xmlrpc")
    end
  end
end
