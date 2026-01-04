# frozen_string_literal: true

require 'spec_helper'

describe 'Admin Routes', type: :routing do
  describe 'Admin::ContentController' do
    it 'routes GET /admin/content to admin/content#index' do
      expect(get: '/admin/content').to route_to(controller: 'admin/content', action: 'index')
    end

    it 'routes GET /admin/content/new to admin/content#new' do
      expect(get: '/admin/content/new').to route_to(controller: 'admin/content', action: 'new')
    end

    it 'routes POST /admin/content/new to admin/content#new' do
      expect(post: '/admin/content/new').to route_to(controller: 'admin/content', action: 'new')
    end

    it 'routes GET /admin/content/edit/1 to admin/content#edit' do
      expect(get: '/admin/content/edit/1').to route_to(controller: 'admin/content', action: 'edit', id: '1')
    end

    it 'routes POST /admin/content/edit/1 to admin/content#edit' do
      expect(post: '/admin/content/edit/1').to route_to(controller: 'admin/content', action: 'edit', id: '1')
    end

    it 'routes POST /admin/content/destroy/1 to admin/content#destroy' do
      expect(post: '/admin/content/destroy/1').to route_to(controller: 'admin/content', action: 'destroy', id: '1')
    end

    it 'routes POST /admin/content/autosave/1 to admin/content#autosave' do
      expect(post: '/admin/content/autosave/1').to route_to(controller: 'admin/content', action: 'autosave', id: '1')
    end
  end

  describe 'Admin::PagesController' do
    it 'routes GET /admin/pages to admin/pages#index' do
      expect(get: '/admin/pages').to route_to(controller: 'admin/pages', action: 'index')
    end

    it 'routes GET /admin/pages/new to admin/pages#new' do
      expect(get: '/admin/pages/new').to route_to(controller: 'admin/pages', action: 'new')
    end

    it 'routes POST /admin/pages/new to admin/pages#new' do
      expect(post: '/admin/pages/new').to route_to(controller: 'admin/pages', action: 'new')
    end

    it 'routes GET /admin/pages/edit/1 to admin/pages#edit' do
      expect(get: '/admin/pages/edit/1').to route_to(controller: 'admin/pages', action: 'edit', id: '1')
    end

    it 'routes POST /admin/pages/edit/1 to admin/pages#edit' do
      expect(post: '/admin/pages/edit/1').to route_to(controller: 'admin/pages', action: 'edit', id: '1')
    end

    it 'routes POST /admin/pages/destroy/1 to admin/pages#destroy' do
      expect(post: '/admin/pages/destroy/1').to route_to(controller: 'admin/pages', action: 'destroy', id: '1')
    end
  end

  describe 'Admin::UsersController' do
    it 'routes GET /admin/users to admin/users#index' do
      expect(get: '/admin/users').to route_to(controller: 'admin/users', action: 'index')
    end

    it 'routes GET /admin/users/new to admin/users#new' do
      expect(get: '/admin/users/new').to route_to(controller: 'admin/users', action: 'new')
    end

    it 'routes GET /admin/users/edit/1 to admin/users#edit' do
      expect(get: '/admin/users/edit/1').to route_to(controller: 'admin/users', action: 'edit', id: '1')
    end

    it 'routes POST /admin/users/edit/1 to admin/users#edit' do
      expect(post: '/admin/users/edit/1').to route_to(controller: 'admin/users', action: 'edit', id: '1')
    end

    it 'routes POST /admin/users/destroy/1 to admin/users#destroy' do
      expect(post: '/admin/users/destroy/1').to route_to(controller: 'admin/users', action: 'destroy', id: '1')
    end
  end

  describe 'Admin::CategoriesController' do
    it 'routes GET /admin/categories to admin/categories#index' do
      expect(get: '/admin/categories').to route_to(controller: 'admin/categories', action: 'index')
    end

    it 'routes GET /admin/categories/new to admin/categories#new' do
      expect(get: '/admin/categories/new').to route_to(controller: 'admin/categories', action: 'new')
    end

    it 'routes GET /admin/categories/edit/1 to admin/categories#edit' do
      expect(get: '/admin/categories/edit/1').to route_to(controller: 'admin/categories', action: 'edit', id: '1')
    end

    it 'routes POST /admin/categories/edit/1 to admin/categories#edit' do
      expect(post: '/admin/categories/edit/1').to route_to(controller: 'admin/categories', action: 'edit', id: '1')
    end
  end

  describe 'Admin::TagsController' do
    it 'routes GET /admin/tags to admin/tags#index' do
      expect(get: '/admin/tags').to route_to(controller: 'admin/tags', action: 'index')
    end

    it 'routes GET /admin/tags/edit/1 to admin/tags#edit' do
      expect(get: '/admin/tags/edit/1').to route_to(controller: 'admin/tags', action: 'edit', id: '1')
    end

    it 'routes POST /admin/tags/edit/1 to admin/tags#edit' do
      expect(post: '/admin/tags/edit/1').to route_to(controller: 'admin/tags', action: 'edit', id: '1')
    end
  end

  describe 'Admin::FeedbackController' do
    it 'routes GET /admin/feedback to admin/feedback#index' do
      expect(get: '/admin/feedback').to route_to(controller: 'admin/feedback', action: 'index')
    end

    it 'routes GET /admin/feedback/edit/1 to admin/feedback#edit' do
      expect(get: '/admin/feedback/edit/1').to route_to(controller: 'admin/feedback', action: 'edit', id: '1')
    end

    it 'routes POST /admin/feedback/edit/1 to admin/feedback#edit' do
      expect(post: '/admin/feedback/edit/1').to route_to(controller: 'admin/feedback', action: 'edit', id: '1')
    end

    it 'routes POST /admin/feedback/destroy/1 to admin/feedback#destroy' do
      expect(post: '/admin/feedback/destroy/1').to route_to(controller: 'admin/feedback', action: 'destroy', id: '1')
    end

    it 'routes POST /admin/feedback/bulkops to admin/feedback#bulkops' do
      expect(post: '/admin/feedback/bulkops/1').to route_to(controller: 'admin/feedback', action: 'bulkops', id: '1')
    end
  end

  describe 'Admin::SettingsController' do
    it 'routes GET /admin/settings to admin/settings#index' do
      expect(get: '/admin/settings').to route_to(controller: 'admin/settings', action: 'index')
    end

    it 'routes GET /admin/settings/write to admin/settings#write' do
      expect(get: '/admin/settings/write').to route_to(controller: 'admin/settings', action: 'write')
    end

    it 'routes POST /admin/settings/write/1 to admin/settings#write' do
      expect(post: '/admin/settings/write/1').to route_to(controller: 'admin/settings', action: 'write', id: '1')
    end
  end

  describe 'Admin::RedirectsController' do
    it 'routes GET /admin/redirects to admin/redirects#index' do
      expect(get: '/admin/redirects').to route_to(controller: 'admin/redirects', action: 'index')
    end

    it 'routes GET /admin/redirects/new to admin/redirects#new' do
      expect(get: '/admin/redirects/new').to route_to(controller: 'admin/redirects', action: 'new')
    end

    it 'routes GET /admin/redirects/edit/1 to admin/redirects#edit' do
      expect(get: '/admin/redirects/edit/1').to route_to(controller: 'admin/redirects', action: 'edit', id: '1')
    end

    it 'routes POST /admin/redirects/edit/1 to admin/redirects#edit' do
      expect(post: '/admin/redirects/edit/1').to route_to(controller: 'admin/redirects', action: 'edit', id: '1')
    end

    it 'routes POST /admin/redirects/destroy/1 to admin/redirects#destroy' do
      expect(post: '/admin/redirects/destroy/1').to route_to(controller: 'admin/redirects', action: 'destroy', id: '1')
    end
  end

  describe 'Admin::SidebarController' do
    it 'routes GET /admin/sidebar to admin/sidebar#index' do
      expect(get: '/admin/sidebar').to route_to(controller: 'admin/sidebar', action: 'index')
    end

    it 'routes POST /admin/sidebar/set_active/1 to admin/sidebar#set_active' do
      expect(post: '/admin/sidebar/set_active/1').to route_to(controller: 'admin/sidebar', action: 'set_active',
                                                              id: '1')
    end

    it 'routes POST /admin/sidebar/remove/1 to admin/sidebar#remove' do
      expect(post: '/admin/sidebar/remove/1').to route_to(controller: 'admin/sidebar', action: 'remove', id: '1')
    end

    it 'routes POST /admin/sidebar/publish/1 to admin/sidebar#publish' do
      expect(post: '/admin/sidebar/publish/1').to route_to(controller: 'admin/sidebar', action: 'publish', id: '1')
    end
  end

  describe 'Admin::ThemesController' do
    it 'routes GET /admin/themes to admin/themes#index' do
      expect(get: '/admin/themes').to route_to(controller: 'admin/themes', action: 'index')
    end

    it 'routes GET /admin/themes/preview to admin/themes#preview' do
      expect(get: '/admin/themes/preview').to route_to(controller: 'admin/themes', action: 'preview')
    end

    it 'routes GET /admin/themes/switchto to admin/themes#switchto' do
      expect(get: '/admin/themes/switchto').to route_to(controller: 'admin/themes', action: 'switchto')
    end
  end

  describe 'Admin::DashboardController' do
    it 'routes GET /admin to admin/dashboard#index' do
      expect(get: '/admin').to route_to(controller: 'admin/dashboard', action: 'index')
    end

    it 'routes GET /admin/dashboard to admin/dashboard#index' do
      expect(get: '/admin/dashboard').to route_to(controller: 'admin/dashboard', action: 'index')
    end

    it 'routes GET /admin/dashboard/index to admin/dashboard#index' do
      expect(get: '/admin/dashboard/index').to route_to(controller: 'admin/dashboard', action: 'index')
    end
  end

  describe 'Admin::ResourcesController' do
    it 'routes GET /admin/resources to admin/resources#index' do
      expect(get: '/admin/resources').to route_to(controller: 'admin/resources', action: 'index')
    end

    it 'routes GET /admin/resources/new to admin/resources#new' do
      expect(get: '/admin/resources/new').to route_to(controller: 'admin/resources', action: 'new')
    end

    it 'routes POST /admin/resources/upload/1 to admin/resources#upload' do
      expect(post: '/admin/resources/upload/1').to route_to(controller: 'admin/resources', action: 'upload', id: '1')
    end

    it 'routes POST /admin/resources/destroy/1 to admin/resources#destroy' do
      expect(post: '/admin/resources/destroy/1').to route_to(controller: 'admin/resources', action: 'destroy', id: '1')
    end
  end

  describe 'Admin::ProfilesController' do
    it 'routes GET /admin/profiles to admin/profiles#index' do
      expect(get: '/admin/profiles').to route_to(controller: 'admin/profiles', action: 'index')
    end

    it 'routes GET /admin/profiles/edit/1 to admin/profiles#edit' do
      expect(get: '/admin/profiles/edit/1').to route_to(controller: 'admin/profiles', action: 'edit', id: '1')
    end

    it 'routes POST /admin/profiles/edit/1 to admin/profiles#edit' do
      expect(post: '/admin/profiles/edit/1').to route_to(controller: 'admin/profiles', action: 'edit', id: '1')
    end
  end

  describe 'Admin::SeoController' do
    it 'routes GET /admin/seo to admin/seo#index' do
      expect(get: '/admin/seo').to route_to(controller: 'admin/seo', action: 'index')
    end

    it 'routes GET /admin/seo/permalinks to admin/seo#permalinks' do
      expect(get: '/admin/seo/permalinks').to route_to(controller: 'admin/seo', action: 'permalinks')
    end

    it 'routes GET /admin/seo/titles to admin/seo#titles' do
      expect(get: '/admin/seo/titles').to route_to(controller: 'admin/seo', action: 'titles')
    end
  end
end
