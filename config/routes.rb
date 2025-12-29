Rails.application.routes.draw do
  # Load plugin routes first
  Dir.glob(File.join("vendor", "plugins", "typo_*")).each do |dir|
    if File.exist?(File.join(dir, "config", "routes.rb"))
      require File.join(dir, "config", "routes.rb")
    end
  end

  # for CK Editor - disabled for now as these controllers may not exist
  # match 'fm/filemanager(/:action(/:id))', to: 'fm/filemanager', format: false, via: [:get, :post]
  # match 'ckeditor/command', to: 'ckeditor#command', format: false, via: [:get, :post]
  # match 'ckeditor/upload', to: 'ckeditor#upload', format: false, via: [:get, :post]

  # Archive routes
  match ':year/:month', to: 'articles#index', constraints: { year: /\d{4}/, month: /\d{1,2}/ }, as: 'articles_by_month', format: false, via: :get
  match ':year/:month/page/:page', to: 'articles#index', constraints: { year: /\d{4}/, month: /\d{1,2}/ }, as: 'articles_by_month_page', format: false, via: :get
  match ':year', to: 'articles#index', constraints: { year: /\d{4}/ }, as: 'articles_by_year', format: false, via: :get
  match ':year/page/:page', to: 'articles#index', constraints: { year: /\d{4}/ }, as: 'articles_by_year_page', format: false, via: :get

  get 'admin', to: 'admin/dashboard#index', format: false, as: :admin_dashboard

  # Define root route first with a name that url_for can use for articles#index
  # This ensures pagination links use '/' instead of '/articles.rss'
  get '/', to: 'articles#index', as: 'articles', format: false

  # Also define root for redirect_to root_path
  root to: 'articles#index'

  get 'articles.rss', to: 'articles#index', defaults: { format: 'rss' }, as: 'rss'
  get 'articles.atom', to: 'articles#index', defaults: { format: 'atom' }, as: 'atom'

  scope controller: 'xml', path: 'xml', as: 'xml' do
    get 'articlerss/:id/feed.xml', action: 'articlerss', format: false
    get 'commentrss/feed.xml', action: 'commentrss', format: false
    get 'trackbackrss/feed.xml', action: 'trackbackrss', format: false
  end

  get 'xml/rss', to: 'xml#feed', defaults: { type: 'feed', format: 'rss' }
  get 'sitemap.xml', to: 'xml#feed', defaults: { format: 'googlesitemap', type: 'sitemap' }

  scope controller: 'xml', path: 'xml' do
    get ':format/feed.xml', action: 'feed', defaults: { type: 'feed' }
    get ':format/:type/:id/feed.xml', action: 'feed'
    get ':format/:type/feed.xml', action: 'feed'
  end

  get 'xml/rsd', to: 'xml#rsd', format: false
  get 'xml/feed', to: 'xml#feed'

  # Backend controller for XML-RPC (MetaWeblog, MovableType, Blogger APIs)
  match 'backend/xmlrpc', to: 'backend#xmlrpc', via: [:get, :post], as: :backend_xmlrpc
  match 'backend/:action', to: 'backend#%{action}', via: [:get, :post]

  # CommentsController
  resources :comments, as: 'admin_comments' do
    collection do
      match :preview, via: [:get, :post]
    end
  end

  # TrackbacksController
  resources :trackbacks
  post "trackbacks/:id/:day/:month/:year", to: 'trackbacks#create', format: false

  # ArticlesController
  get '/live_search/', to: 'articles#live_search', as: :live_search_articles, format: false
  get '/search/:q(.:format)/page/:page', to: 'articles#search', as: 'search_page'
  get '/search(/:q(.:format))', to: 'articles#search', as: 'search'
  get '/search/', to: 'articles#search', as: 'search_base', format: false
  get '/archives/', to: 'articles#archives', format: false
  get '/page/:page', to: 'articles#index', constraints: { page: /\d+/ }, format: false
  get '/pages/*name', to: 'articles#view_page', format: false
  match 'previews(/:id)', to: 'articles#preview', format: false, via: [:get, :post]
  post 'check_password', to: 'articles#check_password', format: false
  get 'articles/markup_help/:id', to: 'articles#markup_help', format: false
  get 'articles/tag', to: 'articles#tag', format: false
  get 'articles/category', to: 'articles#category', format: false

  # SetupController
  match '/setup', to: 'setup#index', format: false, via: [:get, :post]
  match '/setup/confirm', to: 'setup#confirm', format: false, via: [:get, :post]

  # CategoriesController
  resources :categories, except: [:show, :update, :destroy, :edit]
  resources :categories, path: 'category', only: [:show, :edit, :update, :destroy]
  get '/category/:id/page/:page', to: 'categories#show', format: false

  # TagsController
  resources :tags, except: [:show, :update, :destroy, :edit]
  resources :tags, path: 'tag', only: [:show, :edit, :update, :destroy]
  get '/tag/:id/page/:page', to: 'tags#show', format: false
  get '/tags/page/:page', to: 'tags#index', format: false

  # AuthorsController
  get '/author/:id.:format', to: 'authors#show', constraints: { format: /rss|atom/ }
  get '/author(/:id)', to: 'authors#show', format: false

  # ThemesController
  scope controller: 'theme' do
    get 'stylesheets/theme/*filename', action: 'stylesheets', format: false
    get 'javascripts/theme/*filename', action: 'javascript', format: false
    get 'images/theme/*filename', action: 'images', format: false
  end

  # For the tests
  get 'theme/static_view_test', format: false

  # Accounts controller for login/logout
  get 'accounts/login', to: 'accounts#login', as: :login
  post 'accounts/login', to: 'accounts#login'
  get 'accounts/logout', to: 'accounts#logout', as: :logout
  get 'accounts/recover_password', to: 'accounts#recover_password'
  post 'accounts/recover_password', to: 'accounts#recover_password'
  get 'accounts/:action', to: 'accounts#index'

  # Admin controllers
  namespace :admin do
    # Explicit routes for common actions that views link to
    get 'content/new', to: 'content#new', as: 'new_content'
    get 'pages/new', to: 'pages#new', as: 'new_page'
    get 'users/edit/:id', to: 'users#edit', as: 'edit_user'

    # Explicit routes for themes
    get 'themes', to: 'themes#index'
    get 'themes/index', to: 'themes#index'
    get 'themes/preview', to: 'themes#preview'
    get 'themes/switchto', to: 'themes#switchto'

    # Explicit routes for dashboard
    get 'dashboard', to: 'dashboard#index'
    get 'dashboard/index', to: 'dashboard#index'

    %w{advanced cache categories comments content profiles feedback general pages
       resources sidebar textfilters trackbacks users settings tags redirects seo post_types}.each do |ctrl|
      get "/#{ctrl}", to: "#{ctrl}#index", as: nil
      get "/#{ctrl}/:action", controller: ctrl, as: nil
      match "/#{ctrl}/:action/:id", controller: ctrl, via: :all, as: nil
    end
  end

  # Root route is defined earlier with 'as: articles' for correct pagination links
  # The named route 'articles' is used by url_for to generate '/' instead of '/articles.rss'

  get '*from', to: 'articles#redirect', format: false
end
