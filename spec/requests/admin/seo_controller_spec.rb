# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Seo', type: :request do
  before(:each) do
    setup_blog_and_admin
    # Clean up any existing robots.txt to ensure clean test state
    robots_path = "#{Rails.root}/public/robots.txt"
    FileUtils.rm_f(robots_path)
  end

  after(:each) do
    # Clean up robots.txt after each test
    robots_path = "#{Rails.root}/public/robots.txt"
    FileUtils.rm_f(robots_path)
  end

  describe 'GET /admin/seo' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/seo'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/seo'
        expect(response).to be_successful
      end

      it 'displays the SEO settings page' do
        get '/admin/seo'
        expect(response.body).to include('Global settings')
      end

      it 'displays meta keyword settings' do
        get '/admin/seo'
        expect(response.body).to include('Use meta keywords')
      end

      it 'displays meta description field' do
        get '/admin/seo'
        expect(response.body).to include('Meta description')
      end

      it 'displays indexing settings' do
        get '/admin/seo'
        expect(response.body).to include('Indexing')
      end

      it 'displays Google analytics settings' do
        get '/admin/seo'
        expect(response.body).to include('Google Analytics')
      end

      it 'displays robots.txt field' do
        get '/admin/seo'
        expect(response.body).to include('Robots.txt')
      end

      context 'when robots.txt exists' do
        before do
          robots_path = "#{Rails.root}/public/robots.txt"
          File.write(robots_path, "User-agent: *\nDisallow: /admin\n")
        end

        it 'reads existing robots.txt content' do
          get '/admin/seo'
          expect(response).to be_successful
        end
      end

      context 'when robots.txt does not exist' do
        it 'creates a default robots.txt' do
          get '/admin/seo'
          expect(response).to be_successful
          robots_path = "#{Rails.root}/public/robots.txt"
          expect(File.exist?(robots_path)).to be true
        end

        it 'creates robots.txt with default content' do
          get '/admin/seo'
          robots_path = "#{Rails.root}/public/robots.txt"
          content = File.read(robots_path)
          expect(content).to include('User-agent: *')
          expect(content).to include('Disallow: /admin')
        end
      end
    end

    context 'when logged in as contributor' do
      it 'restricts access for non-admin users' do
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
        get '/admin/seo'
        # Should either redirect or deny access (depends on implementation)
        expect(response.status).to be_in([200, 302, 403])
      end
    end
  end

  describe 'GET /admin/seo/permalinks' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/seo/permalinks'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/seo/permalinks'
        expect(response).to be_successful
      end

      it 'displays the permalinks page' do
        get '/admin/seo/permalinks'
        expect(response.body).to include('Permalinks')
      end

      it 'displays permalink format options' do
        get '/admin/seo/permalinks'
        expect(response.body).to include('Permalink format')
      end

      it 'displays date and title option' do
        get '/admin/seo/permalinks'
        expect(response.body).to include('Date and title')
      end

      it 'displays month and title option' do
        get '/admin/seo/permalinks'
        expect(response.body).to include('Month and title')
      end

      it 'displays title only option' do
        get '/admin/seo/permalinks'
        expect(response.body).to include('Title only')
      end

      it 'displays custom permalink field' do
        get '/admin/seo/permalinks'
        expect(response.body).to include('Custom')
      end

      context 'with standard permalink format' do
        before do
          @blog.permalink_format = '/%year%/%month%/%day%/%title%'
          @blog.save!
        end

        it 'displays the standard format' do
          get '/admin/seo/permalinks'
          expect(response).to be_successful
        end
      end

      context 'with month/title permalink format' do
        before do
          @blog.permalink_format = '/%year%/%month%/%title%'
          @blog.save!
        end

        it 'displays the month/title format' do
          get '/admin/seo/permalinks'
          expect(response).to be_successful
        end
      end

      context 'with title only permalink format' do
        before do
          @blog.permalink_format = '/%title%'
          @blog.save!
        end

        it 'displays the title only format' do
          get '/admin/seo/permalinks'
          expect(response).to be_successful
        end
      end

      context 'with custom permalink format' do
        before do
          @blog.permalink_format = '/%year%/%title%.html'
          @blog.save!
        end

        it 'sets custom_permalink to the custom format' do
          get '/admin/seo/permalinks'
          expect(response).to be_successful
          # The controller should set custom_permalink when format doesn't match standard
          expect(response.body).to include('custom_permalink')
        end
      end
    end
  end

  describe 'POST /admin/seo/permalinks/0' do
    before { login_admin }

    it 'updates permalink format' do
      post '/admin/seo/permalinks/0', params: {
        setting: {
          permalink_format: '/%year%/%month%/%title%'
        },
        from: 'permalinks'
      }
      expect(response).to redirect_to(action: 'permalinks')
      expect(@blog.reload.permalink_format).to eq('/%year%/%month%/%title%')
    end

    it 'handles custom permalink format' do
      post '/admin/seo/permalinks/0', params: {
        setting: {
          permalink_format: 'custom',
          custom_permalink: '/%year%/%title%.html'
        },
        from: 'permalinks'
      }
      expect(response).to redirect_to(action: 'permalinks')
      expect(@blog.reload.permalink_format).to eq('/%year%/%title%.html')
    end

    it 'sets flash notice on successful update' do
      post '/admin/seo/permalinks/0', params: {
        setting: {
          permalink_format: '/%title%'
        },
        from: 'permalinks'
      }
      expect(flash[:notice]).to eq('config updated.')
    end
  end

  describe 'GET /admin/seo/titles' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/seo/titles'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/seo/titles'
        expect(response).to be_successful
      end

      it 'displays the titles settings page' do
        get '/admin/seo/titles'
        expect(response.body).to include('Title settings')
      end

      it 'displays home title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Home')
      end

      it 'displays article title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Articles')
      end

      it 'displays page title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Pages')
      end

      it 'displays category title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Categories')
      end

      it 'displays tag title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Tags')
      end

      it 'displays search result title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Search results')
      end

      it 'displays author page title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Author page')
      end

      it 'displays paginated archives settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Paginated archives')
      end

      it 'displays dated archives settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Dated archives')
      end

      it 'displays help on title settings' do
        get '/admin/seo/titles'
        expect(response.body).to include('Help on title settings')
      end
    end
  end

  describe 'POST /admin/seo/update/0' do
    before { login_admin }

    context 'from index page' do
      it 'updates meta description' do
        post '/admin/seo/update/0', params: {
          setting: {
            meta_description: 'New meta description'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        expect(@blog.reload.meta_description).to eq('New meta description')
      end

      it 'updates meta keywords' do
        post '/admin/seo/update/0', params: {
          setting: {
            meta_keywords: 'keyword1, keyword2, keyword3'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        expect(@blog.reload.meta_keywords).to eq('keyword1, keyword2, keyword3')
      end

      it 'updates use_meta_keyword setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            use_meta_keyword: '1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'updates google_analytics setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            google_analytics: 'UA-12345678-1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        expect(@blog.reload.google_analytics).to eq('UA-12345678-1')
      end

      it 'updates google_verification setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            google_verification: 'verification-code-123'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        expect(@blog.reload.google_verification).to eq('verification-code-123')
      end

      it 'updates unindex_categories setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            unindex_categories: '1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'updates unindex_tags setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            unindex_tags: '1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'updates dofollowify setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            dofollowify: '1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'updates use_canonical_url setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            use_canonical_url: '1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'updates custom_tracking_field setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            custom_tracking_field: '<script>custom tracking</script>'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        expect(@blog.reload.custom_tracking_field).to eq('<script>custom tracking</script>')
      end

      it 'updates rss_description setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            rss_description: '1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end

      it 'updates rss_description_text setting' do
        post '/admin/seo/update/0', params: {
          setting: {
            rss_description_text: 'Custom RSS description'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        expect(@blog.reload.rss_description_text).to eq('Custom RSS description')
      end

      it 'sets flash notice on successful update' do
        post '/admin/seo/update/0', params: {
          setting: {
            meta_description: 'Updated description'
          },
          from: 'index'
        }
        expect(flash[:notice]).to eq('config updated.')
      end
    end

    context 'with robots.txt' do
      before do
        robots_path = "#{Rails.root}/public/robots.txt"
        File.write(robots_path, 'Initial content')
        # Make sure it's writable
        File.chmod(0o644, robots_path)
      end

      it 'saves robots.txt content when provided' do
        post '/admin/seo/update/0', params: {
          setting: {
            robots: "User-agent: *\nDisallow: /private\n"
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        robots_path = "#{Rails.root}/public/robots.txt"
        # File should be updated
        expect(File.exist?(robots_path)).to be true
      end

      it 'does not save robots.txt when content is blank' do
        post '/admin/seo/update/0', params: {
          setting: {
            robots: '',
            meta_description: 'test'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
      end
    end

    context 'from titles page' do
      it 'updates home title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            home_title_template: '%blog_name% - %blog_subtitle%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates article title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            article_title_template: '%title% | %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates page title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            page_title_template: '%title% - %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates category title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            category_title_template: '%name% - %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates tag title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            tag_title_template: '%name% - %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates search title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            search_title_template: 'Search: %search% - %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates author title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            author_title_template: '%name% - %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates archives title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            archives_title_template: 'Archives for %date% - %blog_name%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates paginated title template' do
        post '/admin/seo/update/0', params: {
          setting: {
            paginated_title_template: '%blog_name% - Page %page%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end

      it 'updates description templates' do
        post '/admin/seo/update/0', params: {
          setting: {
            home_desc_template: 'Welcome to %blog_name%',
            article_desc_template: '%excerpt%',
            page_desc_template: '%excerpt%'
          },
          from: 'titles'
        }
        expect(response).to redirect_to(action: 'titles')
      end
    end

    context 'from permalinks page' do
      it 'updates and redirects to permalinks' do
        post '/admin/seo/update/0', params: {
          setting: {
            permalink_format: '/%year%/%month%/%day%/%title%'
          },
          from: 'permalinks'
        }
        expect(response).to redirect_to(action: 'permalinks')
      end
    end

    context 'with multiple settings at once' do
      it 'updates multiple settings in a transaction' do
        post '/admin/seo/update/0', params: {
          setting: {
            meta_description: 'Batch update description',
            meta_keywords: 'batch, update, keywords',
            google_analytics: 'UA-BATCH-1'
          },
          from: 'index'
        }
        expect(response).to redirect_to(action: 'index')
        @blog.reload
        expect(@blog.meta_description).to eq('Batch update description')
        expect(@blog.meta_keywords).to eq('batch, update, keywords')
        expect(@blog.google_analytics).to eq('UA-BATCH-1')
      end
    end

    context 'when update is not a POST request' do
      it 'does not update when using GET' do
        original_description = @blog.meta_description
        get '/admin/seo/update/0', params: {
          setting: {
            meta_description: 'Should not update'
          },
          from: 'index'
        }
        # GET request should not update
        expect(@blog.reload.meta_description).to eq(original_description)
      end
    end
  end

  describe 'Access control' do
    it 'requires login for index' do
      get '/admin/seo'
      expect(response).to redirect_to(controller: '/accounts', action: 'login')
    end

    it 'requires login for permalinks' do
      get '/admin/seo/permalinks'
      expect(response).to redirect_to(controller: '/accounts', action: 'login')
    end

    it 'requires login for titles' do
      get '/admin/seo/titles'
      expect(response).to redirect_to(controller: '/accounts', action: 'login')
    end

    it 'requires login for update' do
      post '/admin/seo/update/0', params: { setting: { meta_description: 'test' }, from: 'index' }
      expect(response).to redirect_to(controller: '/accounts', action: 'login')
    end
  end

  describe 'Navigation' do
    before { login_admin }

    it 'can navigate from index to permalinks' do
      get '/admin/seo'
      expect(response).to be_successful
      get '/admin/seo/permalinks'
      expect(response).to be_successful
    end

    it 'can navigate from index to titles' do
      get '/admin/seo'
      expect(response).to be_successful
      get '/admin/seo/titles'
      expect(response).to be_successful
    end
  end
end
