# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :verify_config
  before_action :verify_users, only: %i[login recover_password]

  def index
    if User.none?
      redirect_to action: 'signup'
    else
      redirect_to action: 'login'
    end
  end

  def login
    if session[:user_id] && session[:user_id] == current_user.id
      redirect_back_or_default controller: 'admin/dashboard', action: 'index'
      return
    end

    @page_title = "#{this_blog.blog_name} - #{_('login')}"

    return unless request.post?

    self.current_user = User.authenticate(params[:user][:login], params[:user][:password])

    if logged_in?
      session[:user_id] = current_user.id

      if params[:remember_me] == '1'
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = {
          value: current_user.remember_token,
          expires: current_user.remember_token_expires_at,
          httponly: true # Help prevent auth_token theft.
        }
      end
      add_to_cookies(:typo_user_profile, current_user.profile_label, '/')

      current_user.update_connection_time
      flash[:notice] = _('Login successful')
      redirect_back_or_default controller: 'admin/dashboard', action: 'index'
    else
      flash.now[:error] = _('Login unsuccessful')
      @login = params[:user][:login]
    end
  end

  def signup
    @page_title = "#{this_blog.blog_name} - #{_('signup')}"
    unless User.none? || (this_blog.allow_signup == 1)
      redirect_to action: 'login'
      return
    end

    @user = User.new(signup_params)

    return unless request.post?

    @user.password = generate_password
    session[:tmppass] = @user.password
    @user.name = @user.login
    return unless @user.save

    self.current_user = @user
    session[:user_id] = @user.id

    redirect_to controller: 'accounts', action: 'confirm'
    nil
  end

  def recover_password
    @page_title = "#{this_blog.blog_name} - #{_('Recover your password')}"
    return unless request.post?

    @user = User.where('login = ? or email = ?', params[:user][:login], params[:user][:login]).first

    if @user
      @user.password = generate_password
      @user.save
      flash[:notice] = _('An email has been successfully sent to your address with your new password')
      redirect_to action: 'login'
    else
      flash[:error] = _('Oops, something wrong just happened')
    end
  end

  def logout
    flash[:notice] = _('Successfully logged out')
    current_user.forget_me
    self.current_user = nil
    session[:user_id] = nil
    cookies.delete :auth_token
    cookies.delete :typo_user_profile
    redirect_to action: 'login'
  end

  def confirm
    @page_title = "#{this_blog.blog_name} - #{_('confirm')}"
  end

  private

  def generate_password
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    newpass = ''
    1.upto(7) { |_i| newpass << chars[rand(chars.size - 1)] }
    newpass
  end

  def signup_params
    if params[:user].present?
      params.require(:user).permit(:login, :email, :name)
    else
      {}
    end
  end

  def verify_users
    redirect_to(controller: 'accounts', action: 'signup') if User.none?
    true
  end

  def verify_config
    redirect_to controller: 'setup', action: 'index' unless this_blog.configured?
  end
end
