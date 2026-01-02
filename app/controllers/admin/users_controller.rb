class Admin::UsersController < Admin::BaseController
  cache_sweeper :blog_sweeper

  def index
    @users = User.order('login asc').page(params[:page]).per(this_blog.admin_display_elements)
  end

  def new
    @user = User.new
    @user.attributes = user_params if params[:user].present?
    @user.text_filter = TextFilter.find_by_name(this_blog.text_filter)
    setup_profiles
    @user.name = @user.login
    if request.post? and @user.save
      flash[:notice] = _('User was successfully created.')
      redirect_to :action => 'index'
    end
  end

  def edit
    @user = params[:id] ? User.find_by_id(params[:id]) : current_user

    setup_profiles
    @user.attributes = user_params if params[:user].present?
    if request.post? and @user.save
      if @user.id == current_user.id
        self.current_user = @user
      end
      flash[:notice] = _('User was successfully updated.')
      redirect_to :action => 'index'
    end
  end

  def destroy
    @record = User.find(params[:id])
    return(render 'admin/shared/destroy') unless request.post?

    @record.destroy if User.count > 1
    redirect_to :action => 'index'
  end

  private

  def setup_profiles
    @profiles = Profile.order('id').all
  end

  def user_params
    params.require(:user).permit(
      :login, :password, :password_confirmation, :email,
      :firstname, :lastname, :nickname, :name,
      :profile_id, :state,
      :editor, :text_filter_id,
      :notify_via_email, :notify_on_new_articles, :notify_on_comments,
      :url, :msn, :aim, :yahoo, :twitter, :jabber, :description,
      :show_url, :show_msn, :show_aim, :show_yahoo, :show_twitter, :show_jabber
    )
  end
end
