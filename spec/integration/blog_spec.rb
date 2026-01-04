# frozen_string_literal: true

require 'spec_helper'

describe 'Blog Integration' do
  before(:each) do
    Blog.delete_all
    @blog = Blog.create!(
      base_url: 'http://test.host',
      blog_name: 'Test Blog',
      blog_subtitle: 'A test blog',
      theme: 'scribbish',
      limit_article_display: 10,
      limit_rss_display: 10,
      permalink_format: '/%year%/%month%/%day%/%title%'
    )
    Blog.instance_variable_set(:@default, @blog)
  end

  describe 'Blog model' do
    it 'should have a default blog' do
      expect(Blog.default).to eq(@blog)
    end

    it 'should have a base_url' do
      expect(@blog.base_url).to eq('http://test.host')
    end

    it 'should have a blog_name' do
      expect(@blog.blog_name).to eq('Test Blog')
    end

    it 'should support settings' do
      @blog.blog_subtitle = 'New Subtitle'
      expect(@blog.blog_subtitle).to eq('New Subtitle')
    end
  end

  describe 'Article creation' do
    before(:each) do
      @profile = Profile.find_or_create_by!(label: 'admin') do |p|
        p.nicename = 'Admin'
        p.modules = [:dashboard]
      end
      User.where(login: 'testuser').destroy_all
      @user = User.create!(
        login: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: 'Test User',
        profile: @profile,
        state: 'active'
      )
    end

    it 'should create a published article' do
      article = Article.create!(
        title: 'Test Article',
        body: 'This is a test article body',
        user: @user,
        published: true,
        published_at: Time.now
      )
      expect(article).to be_persisted
      expect(article.title).to eq('Test Article')
    end

    it 'should create an unpublished draft' do
      article = Article.create!(
        title: 'Draft Article',
        body: 'This is a draft',
        user: @user,
        published: false
      )
      expect(article).to be_persisted
      expect(article.published).to be_falsey
    end

    it 'should generate permalink from title' do
      article = Article.create!(
        title: 'My Great Article',
        body: 'Body content',
        user: @user,
        published: true,
        published_at: Time.now
      )
      expect(article.permalink).not_to be_blank
    end
  end

  describe 'User creation' do
    before(:each) do
      @profile = Profile.create!(label: 'usertest', nicename: 'User Test', modules: [:dashboard])
    end

    it 'should create a user with valid attributes' do
      user = User.create!(
        login: 'newuser',
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: 'New User',
        profile: @profile,
        state: 'active'
      )
      expect(user).to be_persisted
      expect(user.login).to eq('newuser')
    end

    it 'should authenticate a user with correct password' do
      user = User.create!(
        login: 'authuser',
        email: 'auth@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: 'Auth User',
        profile: @profile,
        state: 'active'
      )
      authenticated = User.authenticate('authuser', 'password123')
      expect(authenticated).to eq(user)
    end

    it 'should not authenticate with wrong password' do
      User.create!(
        login: 'wrongauth',
        email: 'wrong@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: 'Wrong User',
        profile: @profile,
        state: 'active'
      )
      authenticated = User.authenticate('wrongauth', 'wrongpassword')
      expect(authenticated).to be_nil
    end
  end

  describe 'Category creation' do
    it 'should create a category' do
      category = Category.create!(name: 'Tech', permalink: 'tech')
      expect(category).to be_persisted
    end

    it 'should have a unique permalink' do
      Category.create!(name: 'Tech', permalink: 'tech1')
      expect do
        Category.create!(name: 'Tech', permalink: 'tech1')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'Tag creation' do
    it 'should create a tag' do
      tag = Tag.create!(name: 'ruby', display_name: 'Ruby')
      expect(tag).to be_persisted
    end
  end

  describe 'Page creation' do
    before(:each) do
      @profile = Profile.create!(label: 'admin3', nicename: 'Admin', modules: [:dashboard])
      @user = User.create!(
        login: 'pageuser',
        email: 'page@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: 'Page User',
        profile: @profile,
        state: 'active'
      )
    end

    it 'should create a page' do
      page = Page.create!(
        title: 'About Us',
        body: 'About page content',
        user: @user,
        published: true
      )
      expect(page).to be_persisted
    end
  end
end
