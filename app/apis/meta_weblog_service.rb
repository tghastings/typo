# frozen_string_literal: true

module MetaWeblogStructs
  class Article < ActionWebService::Struct
    member :description,        :string
    member :title,              :string
    member :postid,             :string
    member :url,                :string
    member :link,               :string
    member :permaLink,          :string
    member :categories,         [:string]
    member :mt_text_more,       :string
    member :mt_excerpt,         :string
    member :mt_keywords,        :string
    member :mt_allow_comments,  :int
    member :mt_allow_pings,     :int
    member :mt_convert_breaks,  :string
    member :mt_tb_ping_urls,    [:string]
    member :dateCreated,        :time
  end

  class MediaObject < ActionWebService::Struct
    member :bits, :string
    member :name, :string
    member :type, :string
  end

  class Url < ActionWebService::Struct
    member :url, :string
  end
end

class MetaWeblogApi < ActionWebService::API::Base
  inflect_names false

  api_method :getCategories,
             expects: [{ blogid: :string }, { username: :string }, { password: :string }],
             returns: [[:string]]

  api_method :getPost,
             expects: [{ postid: :string }, { username: :string }, { password: :string }],
             returns: [MetaWeblogStructs::Article]

  api_method :getRecentPosts,
             expects: [{ blogid: :string }, { username: :string }, { password: :string }, { numberOfPosts: :int }],
             returns: [[MetaWeblogStructs::Article]]

  api_method :deletePost,
             expects: [{ appkey: :string }, { postid: :string }, { username: :string }, { password: :string },
                       { publish: :int }],
             returns: [:bool]

  api_method :editPost,
             expects: [{ postid: :string }, { username: :string }, { password: :string },
                       { struct: MetaWeblogStructs::Article }, { publish: :int }],
             returns: [:bool]

  api_method :newPost,
             expects: [{ blogid: :string }, { username: :string }, { password: :string },
                       { struct: MetaWeblogStructs::Article }, { publish: :int }],
             returns: [:string]

  api_method :newMediaObject,
             expects: [{ blogid: :string }, { username: :string }, { password: :string },
                       { data: MetaWeblogStructs::MediaObject }],
             returns: [MetaWeblogStructs::Url]
end

class MetaWeblogService < TypoWebService
  web_service_api MetaWeblogApi
  before_invocation :authenticate

  def getCategories(_blogid, _username, _password)
    Category.all.collect(&:name)
  end

  def getPost(postid, _username, _password)
    article = Article.find(postid)

    article_dto_from(article)
  end

  def getRecentPosts(_blogid, _username, _password, numberOfPosts)
    Article.order('created_at DESC').limit(numberOfPosts).collect { |c| article_dto_from(c) }
  end

  def newPost(_blogid, username, _password, struct, publish)
    article = Article.new
    article.body        = struct['description'] || ''
    article.title       = struct['title'] || ''
    article.author      = username
    article.published_at = begin
      struct['dateCreated'].to_time.getlocal
    rescue StandardError
      Time.now
    end
    article.published   = publish
    article.user        = @user

    # Movable Type API support
    article.allow_comments = struct['mt_allow_comments']  || this_blog.default_allow_comments
    article.allow_pings    = struct['mt_allow_pings']     || this_blog.default_allow_pings
    article.extended       = struct['mt_text_more']       || ''
    article.excerpt        = struct['mt_excerpt']         || ''
    article.text_filter    = TextFilter.find_by_name(struct['mt_convert_breaks'] || this_blog.text_filter)
    article.keywords       = struct['mt_keywords'] || ''

    raise article.errors.full_messages * ', ' unless article.save

    if struct['categories']
      Category.all.each do |c|
        article.categories << c if struct['categories'].include?(c.name)
      end
    end

    article.id.to_s
  end

  def deletePost(_appkey, postid, _username, _password, _publish)
    Article.destroy(postid)
    true
  end

  def editPost(postid, username, _password, struct, publish)
    article = Article.find(postid)
    article.body        = struct['description'] || ''
    article.title       = struct['title'] || ''
    article.published   = publish
    article.author      = username
    article.published_at = struct['dateCreated'].to_time.getlocal unless struct['dateCreated'].blank?

    # Movable Type API support
    article.allow_comments = struct['mt_allow_comments'] || this_blog.default_allow_comments
    article.allow_pings    = struct['mt_allow_pings']    || this_blog.default_allow_pings
    article.extended       = struct['mt_text_more']      || ''
    article.excerpt        = struct['mt_excerpt']        || ''
    article.keywords       = struct['mt_keywords']       || ''
    article.text_filter    = TextFilter.find_by_name(struct['mt_convert_breaks'] || this_blog.text_filter)

    if struct['categories']
      article.categorizations.clear
      Category.all.each do |c|
        article.categories << c if struct['categories'].include?(c.name)
      end
    end

    ::Rails.logger.info(struct['mt_tb_ping_urls'])
    article.save
    true
  end

  def newMediaObject(_blogid, _username, _password, data)
    resource = Resource.create(filename: data['name'], mime: data['type'], created_at: Time.now)
    resource.write_to_disk(data['bits'])

    MetaWeblogStructs::Url.new('url' => this_blog.file_url(resource.filename))
  end

  def article_dto_from(article)
    MetaWeblogStructs::Article.new(
      description: article.body,
      title: article.title,
      postid: article.id.to_s,
      url: article.permalink_url,
      link: article.permalink_url,
      permaLink: article.permalink_url,
      categories: article.categories.collect(&:name),
      mt_text_more: article.extended.to_s,
      mt_excerpt: article.excerpt.to_s,
      mt_keywords: article.tags.collect(&:name).join(', '),
      mt_allow_comments: article.allow_comments? ? 1 : 0,
      mt_allow_pings: article.allow_pings? ? 1 : 0,
      mt_convert_breaks: begin
        article.text_filter.name.to_s
      rescue StandardError
        ''
      end,
      mt_tb_ping_urls: article.pings.collect(&:url),
      dateCreated: begin
        article.published_at.utc
      rescue StandardError
        ''
      end
    )
  end
end
