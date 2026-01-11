# frozen_string_literal: true

module Admin
  class FeedbackController < Admin::BaseController
    cache_sweeper :blog_sweeper

    def index
      conditions = ['1 = 1', {}]

      if params[:search]
        conditions.first << ' and (url like :pattern or author like :pattern or title like :pattern or ip like :pattern or email like :pattern)'
        conditions.last.merge!(pattern: "%#{params[:search]}%")
      end

      if params[:published] == 'f'
        conditions.first << ' and (published = :published)'
        conditions.last.merge!(published: false)
      end

      if params[:confirmed] == 'f'
        conditions.first << ' AND (status_confirmed = :status_confirmed)'
        conditions.last.merge!(status_confirmed: false)
      end

      if params[:ham] == 'f'
        conditions.first << ' AND state = :state '
        conditions.last.merge!(state: 'ham')
      end

      if params[:spam] == 'f'
        conditions.first << ' AND state = :state '
        conditions.last.merge!(state: 'spam')
      end

      if params[:presumed_ham] == 'f'
        conditions.first << ' AND state = :state '
        conditions.last.merge!(state: 'presumed_ham')
      end

      if params[:presumed_spam] == 'f'
        conditions.first << ' AND state = :state '
        conditions.last.merge!(state: 'presumed_spam')
      end

      # no need params[:page] if empty of == 0, there are a crash otherwise
      params.delete(:page) if params[:page].blank? || params[:page] == '0'
      @feedback = Feedback.where(conditions).order('feedback.created_at desc').page(params[:page]).per(this_blog.admin_display_elements)
    end

    def article
      @article = Article.find(params[:id])
      @feedback = @article.comments.ham if params[:ham] && params[:spam].blank?
      @feedback = @article.comments.spam if params[:spam] && params[:ham].blank?
      @article ||= @article.comments
    end

    def destroy
      @record = Feedback.find params[:id]

      return redirect_to controller: 'admin/feedback', action: :index if @record.article.user_id != current_user.id && !current_user.admin?

      return render 'admin/shared/destroy' unless request.post?

      begin
        @record.destroy
        flash[:notice] = _('Deleted')
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = _('Not found')
      end
      redirect_to action: 'article', id: @record.article.id
    end

    def create
      @article = Article.find(params[:article_id])
      @comment = @article.comments.build(comment_params)
      @comment.user_id = current_user.id

      if request.post? && @comment.save
        # We should probably wave a spam filter over this, but for now, just mark it as published.
        @comment.mark_as_ham!
        flash[:notice] = _('Comment was successfully created.')
      end
      redirect_to action: 'article', id: @article.id
    end

    def edit
      @comment = Comment.find(params[:id])
      @article = @comment.article
      return if @article.access_by? current_user

      redirect_to action: 'index'
      nil
    end

    def update
      comment = Comment.find(params[:id])
      unless comment.article.access_by? current_user
        redirect_to action: 'index'
        return
      end
      comment.attributes = comment_params if params[:comment].present?
      if request.post? && comment.save
        flash[:notice] = _('Comment was successfully updated.')
        redirect_to action: 'article', id: comment.article.id
      else
        redirect_to action: 'edit', id: comment.id
      end
    end

    def change_state
      return unless request.xhr?

      feedback = Feedback.find(params[:id])
      if feedback.state.to_s.downcase == 'spam'
        feedback.mark_as_ham!
      else
        feedback.mark_as_spam!
      end

      # Check if client specifically requested turbo-stream format
      if request.accepts.any? { |type| type.to_s.include?('turbo-stream') }
        template = feedback.state.to_s.downcase == 'spam' ? 'spam' : 'ham'
        render turbo_stream: turbo_stream.replace(
          "feedback_#{feedback.id}",
          partial: 'admin/feedback/feedback_row',
          locals: { comment: feedback, template: template }
        )
      elsif params[:context] == 'listing'
        # Return JSON for legacy XHR requests
        html = render_to_string(
          partial: 'admin/feedback/feedback_row',
          locals: { comment: feedback, template: feedback.state.to_s.downcase == 'spam' ? 'spam' : 'ham' }
        )
        render json: { action: 'replace', id: feedback.id, html: html }
      else
        render json: { action: 'fade', id: feedback.id }
      end
    end

    def mark_as_ham
      feedback = Feedback.find(params[:id])
      feedback.mark_as_ham!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "feedback_#{feedback.id}",
            partial: 'admin/feedback/feedback_row',
            locals: { comment: feedback, template: 'ham' }
          )
        end
        format.html { redirect_to action: :index }
      end
    end

    def mark_as_spam
      feedback = Feedback.find(params[:id])
      feedback.mark_as_spam!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "feedback_#{feedback.id}",
            partial: 'admin/feedback/feedback_row',
            locals: { comment: feedback, template: 'spam' }
          )
        end
        format.html { redirect_to action: :index }
      end
    end

    def bulkops
      ids = (params[:feedback_check] || {}).keys.map(&:to_i)
      items = Feedback.find(ids)
      @unexpired = true

      bulkop = params[:bulkop_top].empty? ? params[:bulkop_bottom] : params[:bulkop_top]
      case bulkop
      when 'Delete Checked Items'
        count = 0
        ids.each do |id|
          count += Feedback.delete(id) ## XXX Should this be #destroy?
        end
        flash[:notice] = _('Deleted %d item(s)', count)

        items.each do |i|
          i.invalidates_cache? or next
          flush_cache
          break
        end
      when 'Mark Checked Items as Ham'
        update_feedback(items, :mark_as_ham!)
        flash[:notice] = _('Marked %d item(s) as Ham', ids.size)
      when 'Mark Checked Items as Spam'
        update_feedback(items, :mark_as_spam!)
        flash[:notice] = _('Marked %d item(s) as Spam', ids.size)
      when 'Confirm Classification of Checked Items'
        update_feedback(items, :confirm_classification!)
        flash[:notice] = _('Confirmed classification of %s item(s)', ids.size)
      when 'Delete all spam'
        delete_all_spam
      else
        flash[:notice] = _('Not implemented')
      end

      if params[:article_id]
        redirect_to action: 'article', id: params[:article_id], confirmed: params[:confirmed],
                    published: params[:published]
      else
        redirect_to action: 'index', page: params[:page], search: params[:search],
                    confirmed: params[:confirmed], published: params[:published]
      end
    end

    protected

    def comment_params
      params.require(:comment).permit(:author, :email, :url, :body, :title)
    end

    def delete_all_spam
      return unless request.post?

      Feedback.where('state = ?', 'spam').delete_all
      flash[:notice] = _('All spam have been deleted')
    end

    def update_feedback(items, method)
      items.each do |value|
        value.send(method)
        (@unexpired && value.invalidates_cache?) or next
        flush_cache
      end
    end

    def flush_cache
      @unexpired = false
      PageCache.sweep_all
    end
  end
end
