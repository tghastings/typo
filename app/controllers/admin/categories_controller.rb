class Admin::CategoriesController < Admin::BaseController
  cache_sweeper :blog_sweeper

  def index; redirect_to :action => 'new' ; end
  def edit; new_or_edit;  end

  def new
    respond_to do |format|
      format.html { new_or_edit }
      format.turbo_stream {
        @category = Category.new
        render turbo_stream: turbo_stream.append(
          'category_overlay_container',
          partial: 'admin/categories/overlay_form'
        )
      }
      format.js {
        @category = Category.new
        render turbo_stream: turbo_stream.append(
          'category_overlay_container',
          partial: 'admin/categories/overlay_form'
        )
      }
    end
  end

  def destroy
    @record = Category.find(params[:id])
    return(render 'admin/shared/destroy') unless request.post?

    @record.destroy
    redirect_to :action => 'new'
  end

  private

  def new_or_edit
    @categories = Category.all
    @category = if action_name == 'edit' && params[:id].present?
                  Category.find(params[:id])
                else
                  Category.new
                end
    @category.attributes = category_params if params[:category].present?
    if request.post?
      respond_to do |format|
        format.html { save_category }
        format.turbo_stream do
          if @category.save
            @article = Article.new
            @article.categories << @category
            render turbo_stream: [
              turbo_stream.replace('categories', partial: 'admin/content/categories'),
              turbo_stream.remove('category_overlay')
            ]
          else
            render turbo_stream: turbo_stream.replace('category_overlay', partial: 'admin/categories/overlay_form')
          end
        end
        format.js do
          if @category.save
            @article = Article.new
            @article.categories << @category
            render turbo_stream: [
              turbo_stream.replace('categories', partial: 'admin/content/categories'),
              turbo_stream.remove('category_overlay')
            ]
          else
            render turbo_stream: turbo_stream.replace('category_overlay', partial: 'admin/categories/overlay_form')
          end
        end
      end
      return
    end
    render 'new'
  end

  def save_category
    if @category.save!
      flash[:notice] = _('Category was successfully saved.')
    else
      flash[:error] = _('Category could not be saved.')
    end
    redirect_to :action => 'new'
  end

  def category_params
    params.require(:category).permit(:name, :keywords, :permalink, :description, :position)
  end
end
