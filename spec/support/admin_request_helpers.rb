# frozen_string_literal: true

module AdminRequestHelpers
  def setup_blog_and_admin
    Blog.delete_all
    @blog = FactoryBot.create(:blog)

    # Create admin profile if it doesn't exist
    @admin_profile = Profile.find_by(label: 'admin') || Profile.create!(
      label: 'admin',
      nicename: 'Administrator',
      modules: [:dashboard, :write, :articles, :pages, :feedback, :themes, :sidebar, :users, :seo, :media, :settings, :profile]
    )

    # Create contributor profile
    @contributor_profile = Profile.find_by(label: 'contributor') || Profile.create!(
      label: 'contributor',
      nicename: 'Contributor',
      modules: [:dashboard, :profile]
    )

    # Create admin user
    @admin = User.create!(
      login: 'admin',
      email: 'admin@test.com',
      password: 'password',
      password_confirmation: 'password',
      name: 'Admin User',
      profile: @admin_profile,
      state: 'active'
    )
  end

  def login_admin
    # Use correct parameter structure that AccountsController expects
    post '/accounts/login', params: { user: { login: @admin.login, password: 'password' } }
  end

  def login_user(user, password = 'password')
    post '/accounts/login', params: { user: { login: user.login, password: password } }
  end
end

RSpec.configure do |config|
  config.include AdminRequestHelpers, type: :request
end
