# frozen_string_literal: true

class CommentsController < FeedbackController
  before_action :get_article, only: %i[create preview]

  def create
    @comment = @article.with_options(new_comment_defaults) do |art|
      art.add_comment(params[:comment].to_unsafe_h.symbolize_keys)
    end

    if !(current_user.nil? || session[:user_id].nil?) && (current_user.id == session[:user_id])
      # maybe useless, but who knows ?
      @comment.user_id = current_user.id
    end

    set_cookies_for @comment

    partial = '/articles/comment_failed'
    partial = '/articles/comment' if recaptcha_ok_for?(@comment) && @comment.save
    if request.xhr?
      render partial: partial, object: @comment
    else
      redirect_to @article.permalink_url, allow_other_host: true
    end
  end

  def preview
    session session: new unless session

    params[:comment]
    if begin
      params_comment[:body].blank?
    rescue StandardError
      true
    end
      head :ok
      return
    end

    set_headers
    @comment = Comment.new(params_comment)

    if @article.comments_closed?
      render plain: 'Comment are closed'
    else
      render 'articles/comment_preview', locals: { comment: @comment }
    end
  end

  protected

  def recaptcha_ok_for?(comment)
    use_recaptcha = Blog.default.settings['use_recaptcha']
    (use_recaptcha && verify_recaptcha(model: comment)) || !use_recaptcha
  end

  def get_feedback
    @comments =
      if params[:article_id]
        article = Article.find_by(id: params[:article_id])
        article ? article.published_comments : []
      else
        Comment.where(published: true).order('created_at DESC').limit(this_blog.limit_rss_display)
      end
  end

  def new_comment_defaults
    { ip: request.remote_ip,
      author: 'Anonymous',
      published: true,
      user: @current_user,
      user_agent: request.env['HTTP_USER_AGENT'],
      referrer: request.env['HTTP_REFERER'],
      permalink: @article.permalink_url }
  end

  def set_headers
    headers['Content-Type'] = 'text/html; charset=utf-8'
  end

  def set_cookies_for(comment)
    add_to_cookies(:author, comment.author)
    add_to_cookies(:url, comment.url)
    return if comment.email.blank?

    add_to_cookies(:gravatar_id, Digest::MD5.hexdigest(comment.email.strip))
  end

  def get_article
    @article = Article.find_by(id: params[:article_id])
    return if @article

    render plain: 'Article not found', status: 404
    throw(:abort)
  end
end
