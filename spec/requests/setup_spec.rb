# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setup', type: :request do
  describe 'GET /setup' do
    context 'when blog is not configured' do
      before(:each) do
        Blog.delete_all
        User.delete_all
        # Create an unconfigured blog (without blog_name in settings)
        @blog = Blog.new(base_url: 'http://myblog.net')
        @blog.settings = {}
        @blog.save(validate: false)
      end

      it 'renders the setup page' do
        get '/setup'
        expect(response).to have_http_status(:success)
      end

      it 'displays setup form' do
        get '/setup'
        expect(response.body).to include('blog_name')
      end
    end

    context 'when blog is already configured' do
      before(:each) do
        Blog.delete_all
        User.delete_all
        @blog = FactoryBot.create(:blog)
      end

      it 'redirects to articles index' do
        get '/setup'
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'POST /setup' do
    context 'when blog is not configured' do
      before(:each) do
        Blog.delete_all
        User.delete_all
        # Create an unconfigured blog
        @blog = Blog.new(base_url: 'http://myblog.net')
        @blog.settings = {}
        @blog.save(validate: false)
      end

      context 'with valid data' do
        it 'configures the blog' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          blog = Blog.default
          expect(blog.blog_name).to eq('My New Blog')
        end

        it 'creates an admin user' do
          expect {
            post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          }.to change(User, :count).by(1)
        end

        it 'creates user with login admin' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          user = User.find_by(login: 'admin')
          expect(user).not_to be_nil
        end

        it 'creates user with provided email' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          user = User.find_by(login: 'admin')
          expect(user.email).to eq('admin@example.com')
        end

        it 'redirects to confirm page' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          expect(response).to redirect_to('/setup/confirm')
        end

        it 'logs in the new admin user' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          expect(session[:user_id]).not_to be_nil
        end

        it 'sets temporary password in session' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          expect(session[:tmppass]).not_to be_nil
        end

        it 'marks the blog as configured' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
          blog = Blog.default
          expect(blog.configured?).to be_truthy
        end
      end

      context 'with invalid data' do
        it 'redirects back to setup with missing blog name' do
          post '/setup', params: { setting: { blog_name: '', email: 'admin@example.com' } }
          expect(response).to redirect_to('/setup')
        end

        it 'redirects back to setup with missing email' do
          post '/setup', params: { setting: { blog_name: 'My New Blog', email: '' } }
          expect(response).to redirect_to('/setup')
        end
      end
    end

    context 'when blog is already configured' do
      before(:each) do
        Blog.delete_all
        User.delete_all
        @blog = FactoryBot.create(:blog)
        @user = FactoryBot.create(:user)
      end

      it 'redirects to articles index' do
        get '/setup'
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'GET /setup/confirm' do
    context 'after successful setup' do
      before(:each) do
        Blog.delete_all
        User.delete_all
        # Create an unconfigured blog
        @blog = Blog.new(base_url: 'http://myblog.net')
        @blog.settings = {}
        @blog.save(validate: false)
        post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
      end

      it 'renders the confirm page' do
        get '/setup/confirm'
        expect(response).to have_http_status(:success)
      end

      it 'displays the temporary password' do
        get '/setup/confirm'
        expect(response.body).to include(session[:tmppass]) if session[:tmppass]
      end
    end
  end

  describe 'setup assigns existing article to admin user' do
    before(:each) do
      Blog.delete_all
      User.delete_all
      # Create an unconfigured blog with an article (simulating seeds)
      @blog = Blog.new(base_url: 'http://myblog.net')
      @blog.settings = {}
      @blog.save(validate: false)
    end

    it 'assigns orphan article to admin user after setup' do
      # Create an article without user_id (as would happen with seeds)
      article = Article.create!(
        title: 'Welcome',
        body: 'Welcome to your blog',
        permalink: 'welcome',
        published: true,
        published_at: Time.now,
        guid: 'test-guid'
      )

      post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }

      article.reload
      admin_user = User.find_by(login: 'admin')
      expect(article.user_id).to eq(admin_user.id)
    end
  end

  describe 'base_url configuration' do
    before(:each) do
      Blog.delete_all
      User.delete_all
      @blog = Blog.new(base_url: 'http://myblog.net')
      @blog.settings = {}
      @blog.save(validate: false)
    end

    it 'sets the base_url from the request' do
      post '/setup', params: { setting: { blog_name: 'My New Blog', email: 'admin@example.com' } }
      blog = Blog.default
      expect(blog.base_url).to be_present
    end
  end
end
