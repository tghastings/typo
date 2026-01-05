# frozen_string_literal: true

Rails.application.routes.draw do
  # Load plugin routes first
  Dir.glob(File.join('vendor', 'plugins', 'typo_*')).each do |dir|
    require File.join(dir, 'config', 'routes.rb') if File.exist?(File.join(dir, 'config', 'routes.rb'))
  end

  # for CK Editor - disabled for now as these controllers may not exist
  # match 'fm/filemanager(/:action(/:id))', to: 'fm/filemanager', format: false, via: [:get, :post]
  # match 'ckeditor/command', to: 'ckeditor#command', format: false, via: [:get, :post]
  # match 'ckeditor/upload', to: 'ckeditor#upload', format: false, via: [:get, :post]

  # Serve uploaded files directly (bypasses Active Storage for compatibility)
  get 'files/:filename', to: 'files#show', as: 'serve_file', constraints: { filename: %r{[^/]+} }

  # Archive routes
  match ':year/:month', to: 'articles#index', constraints: { year: /\d{4}/, month: /\d{1,2}/ },
                        as: 'articles_by_month', format: false, via: :get
  match ':year/:month/page/:page', to: 'articles#index', constraints: { year: /\d{4}/, month: /\d{1,2}/ },
                                   as: 'articles_by_month_page', format: false, via: :get
  match ':year', to: 'articles#index', constraints: { year: /\d{4}/ }, as: 'articles_by_year', format: false, via: :get
  match ':year/page/:page', to: 'articles#index', constraints: { year: /\d{4}/ }, as: 'articles_by_year_page',
                            format: false, via: :get

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
  match 'backend/xmlrpc', to: 'backend#xmlrpc', via: %i[get post], as: :backend_xmlrpc
  match 'backend/api', to: 'backend#api', via: %i[get post]

  # CommentsController
  resources :comments, as: 'admin_comments' do
    collection do
      match :preview, via: %i[get post]
    end
  end

  # TrackbacksController
  resources :trackbacks
  post 'trackbacks/:id/:day/:month/:year', to: 'trackbacks#create', format: false

  # ArticlesController
  get '/live_search/', to: 'articles#live_search', as: :live_search_articles, format: false
  get '/search/:q(.:format)/page/:page', to: 'articles#search', as: 'search_page'
  get '/search(/:q(.:format))', to: 'articles#search', as: 'search'
  get '/search/', to: 'articles#search', as: 'search_base', format: false
  get '/archives/', to: 'articles#archives', format: false
  get '/page/:page', to: 'articles#index', constraints: { page: /\d+/ }, format: false
  get '/pages/*name', to: 'articles#view_page', format: false
  match 'previews(/:id)', to: 'articles#preview', format: false, via: %i[get post]
  post 'check_password', to: 'articles#check_password', format: false
  get 'articles/markup_help/:id', to: 'articles#markup_help', format: false
  get 'articles/tag', to: 'articles#tag', format: false
  get 'articles/category', to: 'articles#category', format: false

  # SetupController
  match '/setup', to: 'setup#index', format: false, via: %i[get post]
  match '/setup/confirm', to: 'setup#confirm', format: false, via: %i[get post]

  # CategoriesController
  resources :categories, except: %i[show update destroy edit]
  resources :categories, path: 'category', only: %i[show edit update destroy]
  get '/category/:id/page/:page', to: 'categories#show', format: false

  # TagsController
  resources :tags, except: %i[show update destroy edit]
  resources :tags, path: 'tag', only: %i[show edit update destroy]
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
  get 'accounts', to: 'accounts#index'
  get 'accounts/login', to: 'accounts#login', as: :login
  post 'accounts/login', to: 'accounts#login'
  get 'accounts/logout', to: 'accounts#logout', as: :logout
  get 'accounts/recover_password', to: 'accounts#recover_password'
  post 'accounts/recover_password', to: 'accounts#recover_password'
  get 'accounts/signup', to: 'accounts#signup', as: :signup
  post 'accounts/signup', to: 'accounts#signup'
  get 'accounts/confirm', to: 'accounts#confirm', as: :accounts_confirm

  # Admin controllers
  namespace :admin do
    # Admin root redirects to dashboard
    root to: redirect('/admin/dashboard')

    # Explicit routes for common actions that views link to
    get 'content/new', to: 'content#new', as: 'new_content'
    post 'content/new', to: 'content#new'
    get 'pages/new', to: 'pages#new', as: 'new_page'
    post 'pages/new', to: 'pages#new'
    get 'users/edit/:id', to: 'users#edit', as: 'edit_user'

    # Explicit routes for themes
    get 'themes', to: 'themes#index'
    get 'themes/index', to: 'themes#index'
    get 'themes/preview', to: 'themes#preview'
    get 'themes/switchto', to: 'themes#switchto'

    # Explicit routes for dashboard
    get 'dashboard', to: 'dashboard#index'
    get 'dashboard/index', to: 'dashboard#index'

    # Profile update route (POST to index)
    post 'profiles', to: 'profiles#index'

    # Cache sweep route (POST to index)
    post 'cache', to: 'cache#index'

    # Cache controller
    get 'cache', to: 'cache#index'

    # Categories controller
    get 'categories', to: 'categories#index'
    get 'categories/new', to: 'categories#new'
    post 'categories/new', to: 'categories#new'
    get 'categories/edit/:id', to: 'categories#edit'
    post 'categories/edit/:id', to: 'categories#edit'
    post 'categories/destroy/:id', to: 'categories#destroy'

    # Content controller
    get 'content', to: 'content#index'
    get 'content/new', to: 'content#new'
    post 'content/new', to: 'content#new'
    get 'content/edit/:id', to: 'content#edit'
    post 'content/edit/:id', to: 'content#edit'
    get 'content/destroy/:id', to: 'content#destroy'
    post 'content/destroy/:id', to: 'content#destroy'
    post 'content/autosave', to: 'content#autosave'
    post 'content/preview_markdown', to: 'content#preview_markdown'
    post 'content/insert_editor', to: 'content#insert_editor'
    post 'content/auto_complete_for_article_keywords', to: 'content#auto_complete_for_article_keywords'
    post 'content/attachment_box_add', to: 'content#attachment_box_add'
    post 'content/category_add', to: 'content#category_add'

    # Feedback controller
    get 'feedback', to: 'feedback#index'
    get 'feedback/article/:id', to: 'feedback#article'
    get 'feedback/edit/:id', to: 'feedback#edit'
    post 'feedback/edit/:id', to: 'feedback#edit'
    post 'feedback/update/:id', to: 'feedback#update'
    get 'feedback/destroy/:id', to: 'feedback#destroy'
    post 'feedback/destroy/:id', to: 'feedback#destroy'
    post 'feedback/create', to: 'feedback#create'
    post 'feedback/change_state/:id', to: 'feedback#change_state'
    post 'feedback/mark_as_spam/:id', to: 'feedback#mark_as_spam'
    post 'feedback/mark_as_ham/:id', to: 'feedback#mark_as_ham'
    post 'feedback/bulkops', to: 'feedback#bulkops'

    # Pages controller
    get 'pages', to: 'pages#index'
    get 'pages/new', to: 'pages#new'
    post 'pages/new', to: 'pages#new'
    get 'pages/edit/:id', to: 'pages#edit'
    post 'pages/edit/:id', to: 'pages#edit'
    get 'pages/destroy/:id', to: 'pages#destroy'
    post 'pages/destroy/:id', to: 'pages#destroy'

    # Post types controller
    get 'post_types', to: 'post_types#index'
    get 'post_types/new', to: 'post_types#new'
    post 'post_types/new', to: 'post_types#new'
    get 'post_types/edit/:id', to: 'post_types#edit'
    post 'post_types/edit/:id', to: 'post_types#edit'
    post 'post_types/destroy/:id', to: 'post_types#destroy'

    # Profiles controller
    get 'profiles', to: 'profiles#index'

    # Redirects controller
    get 'redirects', to: 'redirects#index'
    get 'redirects/new', to: 'redirects#new'
    post 'redirects/new', to: 'redirects#new'
    get 'redirects/edit/:id', to: 'redirects#edit'
    post 'redirects/edit/:id', to: 'redirects#edit'
    post 'redirects/destroy/:id', to: 'redirects#destroy'

    # Resources controller
    get 'resources', to: 'resources#index'
    get 'resources/new', to: 'resources#new'
    post 'resources/new', to: 'resources#new'
    post 'resources/upload', to: 'resources#upload'
    post 'resources/update', to: 'resources#update'
    post 'resources/update/:id', to: 'resources#update'
    get 'resources/get_thumbnails', to: 'resources#get_thumbnails'
    get 'resources/serve/:filename', to: 'resources#serve', constraints: { filename: %r{[^/]+} }
    get 'resources/destroy/:id', to: 'resources#destroy'
    post 'resources/destroy/:id', to: 'resources#destroy'

    # SEO controller
    get 'seo', to: 'seo#index'
    get 'seo/permalinks', to: 'seo#permalinks'
    post 'seo/permalinks', to: 'seo#permalinks'
    get 'seo/titles', to: 'seo#titles'
    post 'seo/titles', to: 'seo#titles'
    post 'seo/update', to: 'seo#update'

    # Settings controller
    get 'settings', to: 'settings#index'
    post 'settings/update', to: 'settings#update'
    get 'settings/write', to: 'settings#write'
    post 'settings/write', to: 'settings#write'
    get 'settings/feedback', to: 'settings#feedback'
    post 'settings/feedback', to: 'settings#feedback'

    # Sidebar controller
    get 'sidebar', to: 'sidebar#index'
    post 'sidebar/set_active', to: 'sidebar#set_active'
    post 'sidebar/remove', to: 'sidebar#remove'
    post 'sidebar/remove/:id', to: 'sidebar#remove'
    post 'sidebar/publish', to: 'sidebar#publish'
    get 'sidebar/show_available', to: 'sidebar#show_available'
    get 'sidebar/available', to: 'sidebar#available'

    # Tags controller
    get 'tags', to: 'tags#index'
    get 'tags/new', to: 'tags#new'
    post 'tags/new', to: 'tags#new'
    get 'tags/edit/:id', to: 'tags#edit'
    post 'tags/edit/:id', to: 'tags#edit'
    post 'tags/destroy/:id', to: 'tags#destroy'

    # Textfilters controller
    get 'textfilters', to: 'textfilters#index'
    get 'textfilters/macro_help/:id', to: 'textfilters#macro_help'

    # Users controller
    get 'users', to: 'users#index'
    get 'users/new', to: 'users#new'
    post 'users/new', to: 'users#new'
    get 'users/edit/:id', to: 'users#edit'
    post 'users/edit/:id', to: 'users#edit'
    post 'users/destroy/:id', to: 'users#destroy'
  end

  # Root route is defined earlier with 'as: articles' for correct pagination links
  # The named route 'articles' is used by url_for to generate '/' instead of '/articles.rss'

  get '*from', to: 'articles#redirect', format: false
end
