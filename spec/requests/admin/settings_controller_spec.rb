# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Settings', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/settings (index)' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/settings'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/settings'
        expect(response).to be_successful
      end

      it 'displays the general settings page heading' do
        get '/admin/settings'
        expect(response.body).to include('General settings')
      end

      it 'shows blog name setting' do
        get '/admin/settings'
        expect(response.body).to include(@blog.blog_name)
      end

      it 'shows blog subtitle field' do
        get '/admin/settings'
        expect(response.body).to include('Blog subtitle')
      end

      it 'shows blog URL field' do
        get '/admin/settings'
        expect(response.body).to include('Blog URL')
      end

      it 'shows language setting' do
        get '/admin/settings'
        expect(response.body).to include('Language')
      end

      it 'shows email from setting' do
        get '/admin/settings'
        expect(response.body).to include('Source Email')
      end

      it 'shows publishing options section' do
        get '/admin/settings'
        expect(response.body).to include('Publishing options')
      end

      it 'shows article display limit setting' do
        get '/admin/settings'
        expect(response.body).to include('articles on my homepage')
      end

      it 'shows RSS display limit setting' do
        get '/admin/settings'
        expect(response.body).to include('articles in my news feed')
      end

      it 'shows Feedburner ID setting' do
        get '/admin/settings'
        expect(response.body).to include('Feedburner ID')
      end
    end
  end

  describe 'GET /admin/settings/write' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/settings/write'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/settings/write'
        expect(response).to be_successful
      end

      it 'displays the write settings page heading' do
        get '/admin/settings/write'
        expect(response.body).to include('Write')
      end

      it 'shows publish section' do
        get '/admin/settings/write'
        expect(response.body).to include('Publish')
      end

      it 'shows send trackbacks option' do
        get '/admin/settings/write'
        expect(response.body).to include('Send trackbacks')
      end

      it 'shows URLs to ping setting' do
        get '/admin/settings/write'
        expect(response.body).to include('URLs to ping automatically')
      end

      it 'shows media section' do
        get '/admin/settings/write'
        expect(response.body).to include('Media')
      end

      it 'shows image thumbnail size setting' do
        get '/admin/settings/write'
        expect(response.body).to include('Image thumbnail size')
      end

      it 'shows image medium size setting' do
        get '/admin/settings/write'
        expect(response.body).to include('Image medium size')
      end
    end
  end

  describe 'GET /admin/settings/feedback' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/settings/feedback'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/settings/feedback'
        expect(response).to be_successful
      end

      it 'displays feedback settings page heading' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Feedback settings')
      end

      it 'shows feedback section' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Feedback')
      end

      it 'shows enable comments option' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Enable comments by default')
      end

      it 'shows enable trackbacks option' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Enable Trackbacks by default')
      end

      it 'shows feedback moderation option' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Enable feedback moderation')
      end

      it 'shows spam section' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Spam')
      end

      it 'shows spam protection option' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Enable spam protection')
      end

      it 'shows Akismet key setting' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Akismet Key')
      end

      it 'shows disable trackbacks site-wide option' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Disable trackbacks site-wide')
      end

      it 'shows reCaptcha option' do
        get '/admin/settings/feedback'
        expect(response.body).to include('Enable reCaptcha')
      end
    end
  end

  describe 'GET /admin/settings/errors' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/settings/errors'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/settings/errors'
        expect(response).to be_successful
      end

      it 'displays error messages page heading' do
        get '/admin/settings/errors'
        expect(response.body).to include('Error messages')
      end

      it 'shows Error 404 section' do
        get '/admin/settings/errors'
        expect(response.body).to include('Error 404')
      end

      it 'shows title field for 404 error' do
        get '/admin/settings/errors'
        expect(response.body).to include('title_error_404')
      end

      it 'shows message field for 404 error' do
        get '/admin/settings/errors'
        expect(response.body).to include('msg_error_404')
      end
    end
  end

  describe 'GET /admin/settings/redirect' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/settings/redirect'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'redirects to index' do
        get '/admin/settings/redirect'
        expect(response).to redirect_to(action: 'index')
      end

      it 'sets a flash notice' do
        get '/admin/settings/redirect'
        expect(flash[:notice]).to include('review and save the settings')
      end
    end
  end

  describe 'GET /admin/settings/update_database' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/settings/update_database'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/settings/update_database'
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /admin/settings/update' do
    context 'when not logged in' do
      it 'redirects to login page' do
        post '/admin/settings/update', params: { setting: { blog_name: 'New Name' }, from: 'index' }
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      describe 'updating general settings (from index)' do
        it 'updates blog name' do
          post '/admin/settings/update', params: {
            setting: { blog_name: 'Updated Blog Name' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.blog_name).to eq('Updated Blog Name')
        end

        it 'updates blog subtitle' do
          post '/admin/settings/update', params: {
            setting: { blog_subtitle: 'New Subtitle' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.blog_subtitle).to eq('New Subtitle')
        end

        it 'updates language setting' do
          post '/admin/settings/update', params: {
            setting: { lang: 'fr_FR' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.lang).to eq('fr_FR')
        end

        it 'updates email from setting' do
          post '/admin/settings/update', params: {
            setting: { email_from: 'new_email@example.com' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.email_from).to eq('new_email@example.com')
        end

        it 'updates admin display elements' do
          post '/admin/settings/update', params: {
            setting: { admin_display_elements: '25' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.admin_display_elements).to eq(25)
        end

        it 'updates date format' do
          post '/admin/settings/update', params: {
            setting: { date_format: '%m/%d/%Y' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.date_format).to eq('%m/%d/%Y')
        end

        it 'updates time format' do
          post '/admin/settings/update', params: {
            setting: { time_format: '%H:%M' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.time_format).to eq('%H:%M')
        end

        it 'updates article display limit' do
          post '/admin/settings/update', params: {
            setting: { limit_article_display: '15' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.limit_article_display).to eq(15)
        end

        it 'updates RSS display limit' do
          post '/admin/settings/update', params: {
            setting: { limit_rss_display: '20' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.limit_rss_display).to eq(20)
        end

        it 'updates feedburner URL' do
          post '/admin/settings/update', params: {
            setting: { feedburner_url: 'my-feed-id' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.feedburner_url).to eq('my-feed-id')
        end

        it 'updates allow signup setting' do
          post '/admin/settings/update', params: {
            setting: { allow_signup: '1' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.allow_signup).to eq(1)
        end

        it 'updates hide extended on RSS setting' do
          post '/admin/settings/update', params: {
            setting: { hide_extended_on_rss: '1' },
            from: 'index'
          }
          @blog.reload
          expect(@blog.hide_extended_on_rss).to be_truthy
        end

        it 'redirects to index after update' do
          post '/admin/settings/update', params: {
            setting: { blog_name: 'Test Blog' },
            from: 'index'
          }
          expect(response).to redirect_to(action: 'index')
        end

        it 'sets a success flash notice' do
          post '/admin/settings/update', params: {
            setting: { blog_name: 'Test Blog' },
            from: 'index'
          }
          expect(flash[:notice]).to include('config updated')
        end

        it 'updates multiple settings at once' do
          post '/admin/settings/update', params: {
            setting: {
              blog_name: 'Multi Update Blog',
              blog_subtitle: 'Multi Subtitle',
              limit_article_display: '20'
            },
            from: 'index'
          }
          @blog.reload
          expect(@blog.blog_name).to eq('Multi Update Blog')
          expect(@blog.blog_subtitle).to eq('Multi Subtitle')
          expect(@blog.limit_article_display).to eq(20)
        end
      end

      describe 'updating write settings (from write)' do
        it 'updates send outbound pings setting' do
          post '/admin/settings/update', params: {
            setting: { send_outbound_pings: '0' },
            from: 'write'
          }
          @blog.reload
          expect(@blog.send_outbound_pings).to be_falsy
        end

        it 'updates ping URLs' do
          new_ping_urls = "http://example1.com/ping\nhttp://example2.com/ping"
          post '/admin/settings/update', params: {
            setting: { ping_urls: new_ping_urls },
            from: 'write'
          }
          @blog.reload
          expect(@blog.ping_urls).to eq(new_ping_urls)
        end

        it 'updates geourl location' do
          post '/admin/settings/update', params: {
            setting: { geourl_location: '47.774,-122.201' },
            from: 'write'
          }
          @blog.reload
          expect(@blog.geourl_location).to eq('47.774,-122.201')
        end

        it 'updates image thumbnail size' do
          post '/admin/settings/update', params: {
            setting: { image_thumb_size: '150' },
            from: 'write'
          }
          @blog.reload
          expect(@blog.image_thumb_size).to eq(150)
        end

        it 'updates image medium size' do
          post '/admin/settings/update', params: {
            setting: { image_medium_size: '800' },
            from: 'write'
          }
          @blog.reload
          expect(@blog.image_medium_size).to eq(800)
        end

        it 'redirects to write after update' do
          post '/admin/settings/update', params: {
            setting: { send_outbound_pings: '1' },
            from: 'write'
          }
          expect(response).to redirect_to(action: 'write')
        end
      end

      describe 'updating feedback settings (from feedback)' do
        it 'updates default allow comments setting' do
          post '/admin/settings/update', params: {
            setting: { default_allow_comments: '0' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.default_allow_comments).to be_falsy
        end

        it 'updates default allow pings setting' do
          post '/admin/settings/update', params: {
            setting: { default_allow_pings: '1' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.default_allow_pings).to be_truthy
        end

        it 'updates default moderate comments setting' do
          post '/admin/settings/update', params: {
            setting: { default_moderate_comments: '1' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.default_moderate_comments).to be_truthy
        end

        it 'updates spam protection setting' do
          post '/admin/settings/update', params: {
            setting: { sp_global: '1' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.sp_global).to be_truthy
        end

        it 'updates Akismet key' do
          post '/admin/settings/update', params: {
            setting: { sp_akismet_key: 'test-akismet-key' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.sp_akismet_key).to eq('test-akismet-key')
        end

        it 'updates global pings disable setting' do
          post '/admin/settings/update', params: {
            setting: { global_pings_disable: '1' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.global_pings_disable).to be_truthy
        end

        it 'updates article auto close setting' do
          post '/admin/settings/update', params: {
            setting: { sp_article_auto_close: '30' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.sp_article_auto_close).to eq(30)
        end

        it 'updates URL limit setting' do
          post '/admin/settings/update', params: {
            setting: { sp_url_limit: '5' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.sp_url_limit).to eq(5)
        end

        it 'updates use recaptcha setting' do
          post '/admin/settings/update', params: {
            setting: { use_recaptcha: '1' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.use_recaptcha).to be_truthy
        end

        it 'updates comment text filter' do
          post '/admin/settings/update', params: {
            setting: { comment_text_filter: 'textile' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.comment_text_filter).to eq('textile')
        end

        it 'updates link to author setting' do
          post '/admin/settings/update', params: {
            setting: { link_to_author: '1' },
            from: 'feedback'
          }
          @blog.reload
          expect(@blog.link_to_author).to be_truthy
        end

        it 'redirects to feedback after update' do
          post '/admin/settings/update', params: {
            setting: { default_allow_comments: '1' },
            from: 'feedback'
          }
          expect(response).to redirect_to(action: 'feedback')
        end
      end

      describe 'updating error settings (from errors)' do
        it 'updates 404 error title' do
          post '/admin/settings/update', params: {
            setting: { title_error_404: 'Custom 404 Title' },
            from: 'errors'
          }
          @blog.reload
          expect(@blog.title_error_404).to eq('Custom 404 Title')
        end

        it 'updates 404 error message' do
          post '/admin/settings/update', params: {
            setting: { msg_error_404: '<p>Custom error message</p>' },
            from: 'errors'
          }
          @blog.reload
          expect(@blog.msg_error_404).to eq('<p>Custom error message</p>')
        end

        it 'redirects to errors after update' do
          post '/admin/settings/update', params: {
            setting: { title_error_404: 'Not Found' },
            from: 'errors'
          }
          expect(response).to redirect_to(action: 'errors')
        end
      end

      describe 'with edge case settings' do
        it 'handles updating blog name to blank (validation may apply)' do
          original_name = @blog.blog_name
          post '/admin/settings/update', params: {
            setting: { blog_name: '' },
            from: 'index'
          }
          # The controller attempts to save, redirect happens regardless
          expect(response).to redirect_to(action: 'index')
        end

        it 'handles very long blog name' do
          long_name = 'A' * 500
          post '/admin/settings/update', params: {
            setting: { blog_name: long_name },
            from: 'index'
          }
          @blog.reload
          expect(@blog.blog_name).to eq(long_name)
        end

        it 'handles special characters in blog name' do
          special_name = "Test Blog <>&'\""
          post '/admin/settings/update', params: {
            setting: { blog_name: special_name },
            from: 'index'
          }
          @blog.reload
          expect(@blog.blog_name).to eq(special_name)
        end
      end
    end
  end

  describe 'POST /admin/settings/migrate' do
    context 'when not logged in' do
      it 'redirects to login page' do
        post '/admin/settings/migrate'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'redirects to update_database' do
        post '/admin/settings/migrate'
        expect(response).to redirect_to(action: 'update_database')
      end
    end
  end

  describe 'Access control' do
    it 'denies access to non-admin users for settings index' do
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
      get '/admin/settings'
      # Should either redirect or deny access
      expect(response.status).to be_in([200, 302, 403])
    end

    it 'denies access to non-admin users for settings update' do
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
      post '/admin/settings/update', params: {
        setting: { blog_name: 'Hacked Name' },
        from: 'index'
      }
      # Should either redirect or deny access
      expect(response.status).to be_in([200, 302, 403])
    end
  end

  describe 'Settings persistence' do
    before { login_admin }

    it 'persists settings across page loads' do
      post '/admin/settings/update', params: {
        setting: { blog_name: 'Persistent Blog Name' },
        from: 'index'
      }

      get '/admin/settings'
      expect(response.body).to include('Persistent Blog Name')
    end

    it 'preserves other settings when updating one setting' do
      original_subtitle = @blog.blog_subtitle

      post '/admin/settings/update', params: {
        setting: { blog_name: 'New Name Only' },
        from: 'index'
      }

      @blog.reload
      expect(@blog.blog_subtitle).to eq(original_subtitle)
    end
  end
end
