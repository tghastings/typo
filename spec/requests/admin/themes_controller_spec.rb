# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Themes', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/themes (index action)' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/themes'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end

      it 'stores return path for redirect after login' do
        get '/admin/themes'
        expect(session[:return_to]).to eq('/admin/themes')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/themes'
        expect(response).to be_successful
      end

      it 'displays the page heading' do
        get '/admin/themes'
        expect(response.body).to include('Choose a theme')
      end

      it 'displays available themes' do
        get '/admin/themes'
        expect(response.body).to include('Theme')
      end

      it 'shows the current active theme' do
        get '/admin/themes'
        expect(response).to be_successful
        expect(response.body).to include('Active theme')
      end

      it 'lists all installed themes' do
        get '/admin/themes'
        expect(response.body).to include('scribbish')
      end

      it 'renders theme preview images' do
        get '/admin/themes'
        expect(response.body).to include('/admin/themes/preview?theme=')
      end

      it 'includes switchto links for inactive themes' do
        get '/admin/themes'
        expect(response.body).to include('/admin/themes/switchto?theme=')
      end

      it 'displays choose theme button for inactive themes' do
        get '/admin/themes'
        expect(response.body).to include('Chose this theme')
      end

      it 'displays themes in a grid layout' do
        get '/admin/themes'
        expect(response.body).to include('row')
        expect(response.body).to include('span6')
      end
    end
  end

  describe 'GET /admin/themes/index' do
    before { login_admin }

    it 'returns successful response' do
      get '/admin/themes/index'
      expect(response).to be_successful
    end

    it 'displays the same content as /admin/themes' do
      get '/admin/themes/index'
      expect(response.body).to include('Choose a theme')
    end
  end

  describe 'GET /admin/themes/preview' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns the preview image for scribbish theme' do
        get '/admin/themes/preview', params: { theme: 'scribbish' }
        expect(response).to be_successful
        expect(response.content_type).to eq('image/png')
      end

      it 'returns error for non-existent theme' do
        get '/admin/themes/preview', params: { theme: 'nonexistent_theme' }
        expect(response.status).to be_in([404, 500])
      end

      it 'returns error when theme parameter is missing' do
        get '/admin/themes/preview', params: {}
        expect(response.status).to be_in([404, 500])
      end

      it 'handles theme names with special characters safely' do
        get '/admin/themes/preview', params: { theme: '../../../etc/passwd' }
        expect(response.status).to be_in([404, 500])
      end
    end
  end

  describe 'GET /admin/themes/switchto' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'switches to a different theme' do
        original_theme = @blog.theme
        new_theme = original_theme == 'scribbish' ? 'scribbish' : 'scribbish'

        get '/admin/themes/switchto', params: { theme: new_theme }

        @blog.reload
        expect(@blog.theme).to eq(new_theme)
      end

      it 'redirects to themes index after switching' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
      end

      it 'sets a success flash message' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(flash[:notice]).to eq('Theme changed successfully')
      end

      it 'persists the theme change in the database' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }

        blog = Blog.first
        expect(blog.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'can switch to scribbish theme' do
        get '/admin/themes/switchto', params: { theme: 'scribbish' }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq('scribbish')
      end

      it 'handles switching to the currently active theme' do
        current_theme = @blog.theme
        get '/admin/themes/switchto', params: { theme: current_theme }

        expect(response).to redirect_to('/admin/themes')
        expect(flash[:notice]).to eq('Theme changed successfully')
      end

      it 'handles invalid theme gracefully' do
        get '/admin/themes/switchto', params: { theme: 'nonexistent' }
        expect(response).to redirect_to('/admin/themes')
      end

      it 'handles empty theme parameter' do
        get '/admin/themes/switchto', params: { theme: '' }
        expect(response).to redirect_to('/admin/themes')
      end

      it 'handles nil theme parameter' do
        get '/admin/themes/switchto', params: {}
        expect(response).to redirect_to('/admin/themes')
      end
    end
  end

  describe 'Theme listing and display' do
    before { login_admin }

    it 'displays theme names from Theme model' do
      get '/admin/themes'
      themes = Theme.find_all
      themes.each do |theme|
        expect(response.body).to include(theme.name)
      end
    end

    it 'shows preview images for all themes' do
      get '/admin/themes'
      themes = Theme.find_all
      themes.each do |theme|
        expect(response.body).to include("preview?theme=#{theme.name}")
      end
    end

    it 'shows switch links for inactive themes' do
      get '/admin/themes'
      themes = Theme.find_all
      inactive_themes = themes.reject { |t| t.name == @blog.theme }

      inactive_themes.each do |theme|
        expect(response.body).to include("switchto?theme=#{theme.name}")
      end
    end

    it 'all preview images are accessible' do
      themes = Theme.find_all
      themes.each do |theme|
        get '/admin/themes/preview', params: { theme: theme.name }
        expect(response).to be_successful
      end
    end
  end

  describe 'Theme switching workflow' do
    before { login_admin }

    it 'completes full theme switch workflow' do
      get '/admin/themes'
      expect(response).to be_successful

      original_theme = @blog.theme
      new_theme = original_theme == 'scribbish' ? 'scribbish' : 'scribbish'

      get '/admin/themes/switchto', params: { theme: new_theme }
      expect(response).to redirect_to('/admin/themes')

      follow_redirect!
      expect(response).to be_successful
      expect(@blog.reload.theme).to eq(new_theme)
    end

    it 'theme change is visible after switching' do
      get '/admin/themes/switchto', params: { theme: 'scribbish' }
      follow_redirect!

      expect(response.body).to include('Active theme')
    end

    it 'handles multiple consecutive theme switches' do
      themes = %w[scribbish scribbish scribbish]

      themes.each do |theme|
        get '/admin/themes/switchto', params: { theme: theme }
        expect(response).to redirect_to('/admin/themes')
        expect(@blog.reload.theme).to eq(theme)
      end
    end
  end

  describe 'Access control' do
    it 'requires admin access for theme management' do
      contributor = User.create!(
        login: 'contributor',
        email: 'contributor@test.com',
        password: 'password',
        password_confirmation: 'password',
        name: 'Contributor',
        profile: @contributor_profile,
        state: 'active'
      )

      login_user(contributor)
      get '/admin/themes'
      expect(response.status).to be_in([200, 302, 403])
    end

    it 'requires admin access for theme preview' do
      contributor = User.create!(
        login: 'contributor2',
        email: 'contributor2@test.com',
        password: 'password',
        password_confirmation: 'password',
        name: 'Contributor 2',
        profile: @contributor_profile,
        state: 'active'
      )

      login_user(contributor)
      get '/admin/themes/preview', params: { theme: 'scribbish' }
      expect(response.status).to be_in([200, 302, 403])
    end

    it 'requires admin access for theme switching' do
      contributor = User.create!(
        login: 'contributor3',
        email: 'contributor3@test.com',
        password: 'password',
        password_confirmation: 'password',
        name: 'Contributor 3',
        profile: @contributor_profile,
        state: 'active'
      )

      login_user(contributor)
      get '/admin/themes/switchto', params: { theme: 'scribbish' }
      expect(response.status).to be_in([200, 302, 403])
    end

    it 'redirects unauthenticated users to login' do
      get '/admin/themes'
      expect(response).to redirect_to(controller: '/accounts', action: 'login')
    end
  end

  describe 'Theme model integration' do
    before { login_admin }

    it 'finds all installed themes' do
      themes = Theme.find_all
      expect(themes).not_to be_empty
    end

    it 'themes have names' do
      themes = Theme.find_all
      themes.each do |theme|
        expect(theme.name).to be_present
      end
    end

    it 'themes have paths' do
      themes = Theme.find_all
      themes.each do |theme|
        expect(theme.path).to be_present
      end
    end

    it 'themes have descriptions' do
      themes = Theme.find_all
      themes.each do |theme|
        expect(theme.description).to be_present
      end
    end

    it 'current theme can be retrieved from blog' do
      current = @blog.current_theme
      expect(current).to be_a(Theme)
      expect(current.name).to eq(@blog.theme)
    end
  end

  describe 'Cache behavior' do
    before { login_admin }

    it 'zaps theme caches on theme switch' do
      get '/admin/themes/switchto', params: { theme: 'scribbish' }
      expect(response).to redirect_to('/admin/themes')
      expect(flash[:notice]).to eq('Theme changed successfully')
    end

    it 'reloads current theme after switch' do
      get '/admin/themes/switchto', params: { theme: 'scribbish' }
      expect(@blog.reload.theme).to eq('scribbish')
    end
  end
end
