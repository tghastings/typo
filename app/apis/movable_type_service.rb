# frozen_string_literal: true

module MovableTypeStructs
  class ArticleTitle < ActionWebService::Struct
    member :dateCreated,  :time
    member :userid,       :string
    member :postid,       :string
    member :title,        :string
  end

  class CategoryList < ActionWebService::Struct
    member :categoryId,   :string
    member :categoryName, :string
  end

  class CategoryPerPost < ActionWebService::Struct
    member :categoryName, :string
    member :categoryId,   :string
    member :isPrimary,    :bool
  end

  class TextFilter < ActionWebService::Struct
    member :key,    :string
    member :label,  :string
  end

  class TrackBack < ActionWebService::Struct
    member :pingTitle,  :string
    member :pingURL,    :string
    member :pingIP,     :string
  end
end

class MovableTypeApi < ActionWebService::API::Base
  inflect_names false

  api_method :getCategoryList,
             expects: [{ blogid: :string }, { username: :string }, { password: :string }],
             returns: [[MovableTypeStructs::CategoryList]]

  api_method :getPostCategories,
             expects: [{ postid: :string }, { username: :string }, { password: :string }],
             returns: [[MovableTypeStructs::CategoryPerPost]]

  api_method :getRecentPostTitles,
             expects: [{ blogid: :string }, { username: :string }, { password: :string }, { numberOfPosts: :int }],
             returns: [[MovableTypeStructs::ArticleTitle]]

  api_method :setPostCategories,
             expects: [{ postid: :string }, { username: :string }, { password: :string },
                       { categories: [MovableTypeStructs::CategoryPerPost] }],
             returns: [:bool]

  api_method :supportedMethods,
             expects: [],
             returns: [[:string]]

  api_method :supportedTextFilters,
             expects: [],
             returns: [[MovableTypeStructs::TextFilter]]

  api_method :getTrackbackPings,
             expects: [{ postid: :string }],
             returns: [[MovableTypeStructs::TrackBack]]

  api_method :publishPost,
             expects: [{ postid: :string }, { username: :string }, { password: :string }],
             returns: [:bool]
end

class MovableTypeService < TypoWebService
  web_service_api MovableTypeApi

  before_invocation :authenticate, except: %i[getTrackbackPings supportedMethods supportedTextFilters]

  def getRecentPostTitles(blogid, _username, _password, numberOfPosts)
    Article.order('created_at DESC').limit(numberOfPosts).collect do |article|
      MovableTypeStructs::ArticleTitle.new(
        dateCreated: article.created_at,
        userid: blogid.to_s,
        postid: article.id.to_s,
        title: article.title
      )
    end
  end

  def getCategoryList(_blogid, _username, _password)
    Category.all.collect do |c|
      MovableTypeStructs::CategoryList.new(
        categoryId: c.id,
        categoryName: c.name
      )
    end
  end

  def getPostCategories(postid, _username, _password)
    Article.find(postid).categorizations.collect do |c|
      MovableTypeStructs::CategoryPerPost.new(
        categoryName: c.category.name,
        categoryId: c.category_id.to_i,
        isPrimary: c.is_primary
      )
    end
  end

  def setPostCategories(postid, _username, _password, categories)
    article = Article.find(postid)
    article.categories.clear unless categories.nil?

    categories.each do |c|
      category = Category.find(c['categoryId'])
      article.add_category(category, c['isPrimary'])
    end
    article.save
  end

  def supportedMethods
    MovableTypeApi.api_methods.keys.collect(&:to_s)
  end

  # Support for markdown and textile formatting dependant on the relevant
  # translators being available.
  def supportedTextFilters
    TextFilter.all.collect do |filter|
      MovableTypeStructs::TextFilter.new(key: filter.name, label: filter.description)
    end
  end

  def getTrackbackPings(postid)
    article = Article.find(postid)
    article.trackbacks.collect do |t|
      MovableTypeStructs::TrackBack.new(
        pingTitle: t.title.to_s,
        pingURL: t.url.to_s,
        pingIP: t.ip.to_s
      )
    end
  end

  def publishPost(postid, _username, _password)
    article = Article.find(postid)
    article.published = true
    article.save
  end
end
