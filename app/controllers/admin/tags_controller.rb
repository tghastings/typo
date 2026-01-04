# frozen_string_literal: true

module Admin
  class TagsController < Admin::BaseController
    cache_sweeper :blog_sweeper

    def index
      @tags = Tag.order('display_name').page(params[:page]).per(this_blog.admin_display_elements)
    end

    def edit
      @tag = Tag.find(params[:id])
      @tag.attributes = tag_params if params[:tag].present?

      return unless request.post?

      old_name = @tag.name

      return unless @tag.save

      # Create a redirection to ensure nothing nasty happens in the future
      Redirect.create(from_path: "/tag/#{old_name}", to_path: @tag.permalink_url(nil, true))

      flash[:notice] = _('Tag was successfully updated.')
      redirect_to action: 'index'
    end

    def destroy
      @record = Tag.find(params[:id])
      return render 'admin/shared/destroy' unless request.post?

      @record.destroy
      redirect_to action: 'index'
    end

    private

    def tag_params
      params.require(:tag).permit(:display_name, :name)
    end
  end
end
