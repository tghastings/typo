# coding: utf-8
FactoryBot.define do
  sequence :name do |n|
    "name_#{n}"
  end

  sequence :user do |n|
    "user#{n}"
  end

  sequence :guid do |n|
    "deadbeef#{n}"
  end

  sequence :label do |n|
    "lab_#{n}"
  end

  sequence :file_name do |f|
    "file_name_#{f}"
  end

  sequence :category do |n|
    "c_#{n}"
  end

  sequence :time do |n|
    Time.now - n
  end

  factory :user do
    login { generate(:user) }
    email { "#{generate(:user)}@example.com" }
    name { 'Bond' }
    notify_via_email { false }
    notify_on_new_articles { false }
    notify_on_comments { false }
    password { 'top-secret' }
    settings { {} }
    state { 'active' }
    association :profile
    association :text_filter, factory: :textile
  end

  factory :article do
    title { 'A big article' }
    body { 'A content with several data' }
    extended { 'extended content for fun' }
    guid { generate(:guid) }
    permalink { 'a-big-article' }
    published_at { '2005-01-01 02:00:00' }
    updated_at { generate(:time) }
    association :user
    allow_comments { true }
    published { true }
    allow_pings { true }

    factory :unpublished_article do
      published_at { nil }
      published { false }
    end

    factory :utf8article do
      title { 'ルビー' }
      permalink { 'ルビー' }
    end

    factory :second_article do
      title { 'Another big article' }
      published_at { Time.now - 2.seconds }
    end

    factory :article_with_accent_in_html do
      title { 'article with accent' }
      body { '&eacute;coute The future is cool!' }
      permalink { 'article-with-accent' }
      published_at { Time.now - 2.seconds }
    end
  end

  factory :post_type do
    name { 'foobar' }
    description { "Some description" }
  end

  factory :text_filter do
    name { "markdown" }
    description { "Markdown" }
    markup { 'markdown' }
    filters { '--- []' }
    params { '--- {}' }

    factory :markdown do
      name { "markdown" }
      description { "Markdown" }
      markup { 'markdown' }
    end

    factory :smartypants do
      name { "smartypants" }
      description { "SmartyPants" }
      markup { 'none' }
      filters { [:smartypants] }
    end

    factory :markdown_smartypants, aliases: [:"markdown smartypants"] do
      name { "markdown smartypants" }
      description { "Markdown with SmartyPants" }
      markup { 'markdown' }
      filters { [:smartypants] }
    end

    factory :textile do
      name { "textile" }
      description { "Textile" }
      markup { 'textile' }
    end

    factory :none_filter, aliases: [:none] do
      name { "none" }
      description { "None" }
      markup { 'none' }
    end
  end

  factory :blog do
    transient do
      allow_signup { 0 }
    end

    base_url { 'http://myblog.net' }
    blog_name { 'test blog' }
    hide_extended_on_rss { true }
    limit_article_display { 2 }
    sp_url_limit { 3 }
    plugin_avatar { '' }
    blog_subtitle { 'test subtitles' }
    limit_rss_display { 10 }
    ping_urls { 'http://ping.example.com/ping http://alsoping.example.com/rpc/ping' }
    geourl_location { '' }
    default_allow_pings { false }
    send_outbound_pings { false }
    sp_global { true }
    default_allow_comments { true }
    email_from { 'scott@sigkill.org' }
    theme { 'typographic' }
    text_filter { 'textile' }
    sp_article_auto_close { 0 }
    link_to_author { false }
    comment_text_filter { 'markdown' }
    permalink_format { '/%year%/%month%/%day%/%title%' }
    use_canonical_url { true }

    initialize_with do
      # Always get fresh blog from database
      existing = Blog.uncached { Blog.order(:id).first }
      if existing
        existing
      else
        new(attributes)
      end
    end

    to_create do |blog, evaluator|
      if blog.persisted?
        # Apply settings from evaluator to persisted blog
        blog.base_url = evaluator.base_url
        blog.blog_name = evaluator.blog_name
        blog.hide_extended_on_rss = evaluator.hide_extended_on_rss
        blog.limit_article_display = evaluator.limit_article_display
        blog.sp_url_limit = evaluator.sp_url_limit
        blog.plugin_avatar = evaluator.plugin_avatar
        blog.blog_subtitle = evaluator.blog_subtitle
        blog.limit_rss_display = evaluator.limit_rss_display
        blog.ping_urls = evaluator.ping_urls
        blog.geourl_location = evaluator.geourl_location
        blog.default_allow_pings = evaluator.default_allow_pings
        blog.send_outbound_pings = evaluator.send_outbound_pings
        blog.sp_global = evaluator.sp_global
        blog.default_allow_comments = evaluator.default_allow_comments
        blog.email_from = evaluator.email_from
        blog.theme = evaluator.theme
        blog.text_filter = evaluator.text_filter
        blog.sp_article_auto_close = evaluator.sp_article_auto_close
        blog.link_to_author = evaluator.link_to_author
        blog.comment_text_filter = evaluator.comment_text_filter
        blog.permalink_format = evaluator.permalink_format
        blog.use_canonical_url = evaluator.use_canonical_url
        # Apply allow_signup from transient attribute
        blog.allow_signup = evaluator.allow_signup
        blog.save! if blog.changed?
      else
        blog.save!
      end
    end
  end

  factory :profile do
    label { generate(:label) }
    nicename { 'Typo contributor' }
    modules { [:dashboard, :profile] }

    initialize_with do
      requested = attributes[:label]
      if requested
        Profile.find_by(label: requested) || new(attributes)
      else
        new(attributes)
      end
    end

    to_create do |profile|
      profile.save! unless profile.persisted?
    end

    factory :profile_admin do
      nicename { 'Typo administrator' }
      modules { [:dashboard, :write, :articles, :pages, :feedback, :themes, :sidebar, :users, :seo, :media, :settings, :profile] }
    end

    factory :profile_publisher do
      label { 'publisher' }
      nicename { 'Blog publisher' }
      modules { [:users, :dashboard, :write, :articles, :pages, :feedback, :media] }
    end

    factory :profile_contributor do
      label { 'contributor' }
      nicename { 'Blog contributor' }
      modules { [:dashboard, :profile] }
    end
  end

  factory :category do
    name { generate(:category) }
    permalink { generate(:category) }
    position { 1 }
  end

  factory :tag do
    name { generate(:name) }
    display_name { |tag| tag.name }
  end

  factory :resource do
    filename { generate(:file_name) }
    mime { 'image/jpeg' }
    size { 110 }
  end

  factory :redirect do
    from_path { 'foo/bar' }
    to_path { '/someplace/else' }
  end

  factory :comment do
    published { true }
    association :article
    association :text_filter, factory: :textile
    author { 'Bob Foo' }
    url { 'http://fakeurl.com' }
    body { 'Test <a href="http://fakeurl.co.uk">body</a>' }
    created_at { '2005-01-01 02:00:00' }
    updated_at { '2005-01-01 02:00:00' }
    published_at { '2005-01-01 02:00:00' }
    guid { '12313123123123123' }
    state { 'ham' }

    factory :spam_comment do
      state { 'spam' }
      published { false }
    end
  end

  factory :page do
    name { 'page_one' }
    title { 'Page One Title' }
    body { 'ho ho ho' }
    created_at { '2005-05-05 01:00:01' }
    published_at { '2005-05-05 01:00:01' }
    updated_at { '2005-05-05 01:00:01' }
    association :user
    published { true }
    state { 'published' }
  end

  factory :trackback do
    published { true }
    state { 'ham' }
    association :article
    status_confirmed { true }
    blog_name { 'Trackback Blog' }
    title { 'Trackback Entry' }
    url { 'http://www.example.com' }
    excerpt { 'This is an excerpt' }
    guid { 'dsafsadffsdsf' }
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :sidebar do
    active_position { 1 }
    config { {} }
    type { 'Sidebar' }
  end
end

def some_user
  User.first || create(:user)
end

def some_article
  Article.first || create(:article)
end
