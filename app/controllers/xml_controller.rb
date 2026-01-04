# frozen_string_literal: true

class XmlController < ApplicationController
  # Disable page caching for consistency
  # caches_page :feed, :if => Proc.new {|c|
  #   c.request.query_string == ''
  # }

  NORMALIZED_FORMAT_FOR = { 'atom' => 'atom', 'rss' => 'rss',
                            'atom10' => 'atom', 'atom03' => 'atom', 'rss20' => 'rss',
                            'googlesitemap' => 'googlesitemap', 'rsd' => 'rsd' }.freeze

  CONTENT_TYPE_FOR = { 'rss' => 'application/xml',
                       'atom' => 'application/atom+xml',
                       'googlesitemap' => 'application/xml' }.freeze

  def feed
    adjust_format
    @format = params[:format]

    return render plain: 'Unsupported format', status: 404 unless @format

    # TODO: Move redirects into config/routes.rb, if possible
    case params[:type]
    when 'feed'
      if @format == 'atom'
        redirect_to atom_url, status: :moved_permanently
      else
        redirect_to rss_url, status: :moved_permanently
      end
    when 'comments'
      redirect_to admin_comments_url(format: @format), status: :moved_permanently
    when 'article'
      article = Article.find_by(id: params[:id])
      return render plain: 'Article not found', status: 404 unless article

      redirect_to article.permalink_by_format(@format), status: :moved_permanently, allow_other_host: true
    when 'category', 'tag', 'author'
      redirect_to send("#{params[:type]}_url", params[:id], format: @format), status: :moved_permanently
    when 'trackbacks'
      redirect_to trackbacks_url(format: @format), status: :moved_permanently
    when 'sitemap'
      prep_sitemap

      respond_to(&:googlesitemap)
    else
      render plain: 'Unsupported feed type', status: 404
    end
  end

  # TODO: Move redirects into config/routes.rb, if possible
  def articlerss
    article = Article.find_by(id: params[:id])
    return render plain: 'Article not found', status: 404 unless article

    redirect_to article.permalink_by_format('rss'), status: :moved_permanently, allow_other_host: true
  end

  def commentrss
    redirect_to admin_comments_url(format: 'rss'), status: :moved_permanently
  end

  def trackbackrss
    redirect_to trackbacks_url(format: 'rss'), status: :moved_permanently
  end

  def rsd
    respond_to do |format|
      format.rsd
      format.html { render 'rsd', formats: [:rsd] }
    end
  end

  protected

  def adjust_format
    params[:format] = if params[:format]
                        NORMALIZED_FORMAT_FOR[params[:format]]
                      else
                        'rss'
                      end
    # Set the request format based on the normalized format
    if params[:format]
      mime_type = Mime::Type.lookup_by_extension(params[:format])
      request.format = mime_type.to_sym if mime_type
    end
    true
  end

  def fetch_items(association, order = 'published_at DESC', limit = nil)
    association = association.to_s.singularize.classify.constantize if association.instance_of?(Symbol)
    limit ||= this_blog.limit_rss_display
    @items += association.find_already_published.order(order).limit(limit)
  end

  def prep_sitemap
    @items = []
    @blog = this_blog

    @feed_title = this_blog.blog_name
    @link = this_blog.base_url
    @self_url = url_for(params.to_unsafe_h.symbolize_keys.merge(only_path: false))

    fetch_items(:articles, 'created_at DESC', 1000)
    fetch_items(:pages, 'created_at DESC', 1000)

    @items += Category.find_all_with_article_counters(1000) unless this_blog.unindex_categories
    @items += Tag.find_all_with_article_counters(1000) unless this_blog.unindex_tags
  end
end
