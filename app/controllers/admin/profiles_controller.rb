# frozen_string_literal: true

module Admin
  class ProfilesController < Admin::BaseController
    helper Admin::UsersHelper

    def index
      @user = current_user
      @profiles = Profile.order(:id)
      @user.attributes = profile_params if params[:user].present?
      return unless request.post? && @user.save

      self.current_user = @user
      flash[:notice] = _('User was successfully updated.')
    end

    private

    def profile_params
      params.require(:user).permit(
        :email, :name, :login, :password, :password_confirmation,
        :firstname, :lastname, :nickname, :description, :url,
        :msn, :aim, :yahoo, :twitter, :jabber,
        :show_url, :show_msn, :show_aim, :show_yahoo, :show_twitter, :show_jabber,
        :notify_via_email, :notify_on_new_articles, :notify_on_comments,
        :editor, :admin_theme, :text_filter_id
      )
    end
  end
end
