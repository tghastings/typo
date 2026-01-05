# frozen_string_literal: true

class SetupController < ApplicationController
  before_action :check_config, only: 'index'
  layout 'accounts'

  def index
    @blog = Blog.table_exists? ? Blog.first_or_initialize : Blog.new
    return unless request.post?

    @blog.blog_name = params[:setting][:blog_name]
    @blog.base_url = blog_base_url

    @user = User.new(login: 'admin', email: params[:setting][:email])
    @user.password = generate_password
    @user.name = @user.login

    unless @blog.valid? && @user.valid?
      redirect_to action: 'index'
      return
    end

    return unless @blog.save

    session[:tmppass] = @user.password

    return unless @user.save

    self.current_user = @user
    session[:user_id] = @user.id

    # FIXME: Crappy hack : by default, the auto generated post is user_id less and it makes Typo crash
    if User.one?
      art = Article.first
      if art
        art.user_id = @user.id
        art.save
      end
    end
    redirect_to action: 'confirm'
  end

  private

  def generate_password
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    newpass = +''
    1.upto(7) { |_i| newpass << chars[rand(chars.size - 1)] }
    newpass
  end

  def check_config
    return unless this_blog&.configured?

    redirect_to controller: 'articles', action: 'index'
  end
end
