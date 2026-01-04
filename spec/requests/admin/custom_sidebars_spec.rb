# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom Sidebars Integration', type: :request do
  before(:each) do
    setup_blog_and_admin
    login_admin
    Sidebar.delete_all
  end

  shared_examples 'a working sidebar' do |sidebar_class, short_name|
    describe "#{sidebar_class} full workflow" do
      it 'appears in available sidebars list' do
        get '/admin/sidebar'
        expect(response).to be_successful
        expect(response.body).to include(short_name)
      end

      it 'can be created via set_active (drag and drop)' do
        get '/admin/sidebar'
        expect do
          post '/admin/sidebar/set_active', params: { active: [short_name] }, xhr: true
        end.to change { Sidebar.count }.by(1)

        expect(Sidebar.last).to be_a(sidebar_class)
      end

      it 'persists with active_position after set_active' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: { active: [short_name] }, xhr: true

        sidebar = Sidebar.last
        expect(sidebar.active_position).not_to be_nil
        expect(sidebar.active_position).to eq(0)
      end

      it 'remains active after page reload' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: { active: [short_name] }, xhr: true
        sidebar_id = Sidebar.last.id

        # Simulate page reload
        get '/admin/sidebar'

        expect(Sidebar.find(sidebar_id).active_position).not_to be_nil
      end

      it 'can be published with configuration' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: { active: [short_name] }, xhr: true
        sidebar = Sidebar.last

        post '/admin/sidebar/publish', params: {
          configure: {
            sidebar.id.to_s => { 'title' => 'Custom Title', 'show_example_content' => '1' }
          }
        }

        expect(response).to redirect_to(action: :index)
        sidebar.reload
        expect(sidebar.active_position).not_to be_nil
        expect(sidebar.config['title']).to eq('Custom Title')
      end

      it 'persists after publish and reload' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: { active: [short_name] }, xhr: true
        sidebar = Sidebar.last

        post '/admin/sidebar/publish', params: {
          configure: { sidebar.id.to_s => { 'title' => 'Test' } }
        }

        # Clear session and reload
        get '/admin/sidebar'

        reloaded = Sidebar.find(sidebar.id)
        expect(reloaded).to be_a(sidebar_class)
        expect(reloaded.active_position).not_to be_nil
      end

      it 'shows in active sidebars list after creation' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: { active: [short_name] }, xhr: true
        post '/admin/sidebar/publish', params: {
          configure: { Sidebar.last.id.to_s => {} }
        }

        get '/admin/sidebar'
        expect(response.body).to include('Active Sidebar')
      end

      it 'can coexist with other sidebar types' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: {
          active: [short_name, 'static', 'search']
        }, xhr: true

        expect(Sidebar.count).to eq(3)
        expect(Sidebar.find_all_visible.map(&:class)).to include(sidebar_class)
      end

      it 'maintains position when reordered' do
        # Create initial sidebars
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: {
          active: ['static', short_name, 'search']
        }, xhr: true

        custom_sidebar = Sidebar.find_by(type: sidebar_class.to_s)
        static_sidebar = Sidebar.find_by(type: 'StaticSidebar')
        search_sidebar = Sidebar.find_by(type: 'SearchSidebar')

        expect(static_sidebar.active_position).to eq(0)
        expect(custom_sidebar.active_position).to eq(1)
        expect(search_sidebar.active_position).to eq(2)
      end

      it 'is not deleted when other sidebars are reordered' do
        get '/admin/sidebar'
        post '/admin/sidebar/set_active', params: { active: [short_name, 'static'] }, xhr: true
        custom_id = Sidebar.find_by(type: sidebar_class.to_s).id
        static_id = Sidebar.find_by(type: 'StaticSidebar').id

        # Reorder: move static before custom
        post '/admin/sidebar/set_active', params: {
          active: ["static-#{static_id}", "#{short_name}-#{custom_id}"]
        }, xhr: true

        expect(Sidebar.exists?(custom_id)).to be true
        expect(Sidebar.find(custom_id).active_position).not_to be_nil
      end
    end
  end

  describe 'FlickrSidebar' do
    it_behaves_like 'a working sidebar', FlickrSidebar, 'flickr'

    it 'saves flickr_user_id configuration' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: { active: ['flickr'] }, xhr: true
      sidebar = Sidebar.last

      post '/admin/sidebar/publish', params: {
        configure: {
          sidebar.id.to_s => {
            'title' => 'My Photos',
            'flickr_user_id' => '12345678@N00',
            'photo_count' => '8',
            'show_example_content' => '1'
          }
        }
      }

      sidebar.reload
      expect(sidebar.flickr_user_id).to eq('12345678@N00')
      expect(sidebar.photo_count).to eq('8')
      expect(sidebar.show_example_content).to be true
    end
  end

  describe 'SpotifySidebar' do
    it_behaves_like 'a working sidebar', SpotifySidebar, 'spotify'

    it 'saves spotify credentials configuration' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: { active: ['spotify'] }, xhr: true
      sidebar = Sidebar.last

      post '/admin/sidebar/publish', params: {
        configure: {
          sidebar.id.to_s => {
            'title' => 'My Music',
            'client_id' => 'test_client_id',
            'client_secret' => 'test_secret',
            'refresh_token' => 'test_token',
            'show_example_content' => '1'
          }
        }
      }

      sidebar.reload
      expect(sidebar.client_id).to eq('test_client_id')
      expect(sidebar.client_secret).to eq('test_secret')
      expect(sidebar.show_example_content).to be true
    end
  end

  describe 'CodStatsSidebar' do
    it_behaves_like 'a working sidebar', CodStatsSidebar, 'cod'

    it 'saves cod tracker configuration' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: { active: ['cod'] }, xhr: true
      sidebar = Sidebar.last

      post '/admin/sidebar/publish', params: {
        configure: {
          sidebar.id.to_s => {
            'title' => 'My Stats',
            'tracker_api_key' => 'test_api_key',
            'platform' => 'psn',
            'username' => 'TestPlayer',
            'show_example_content' => '1'
          }
        }
      }

      sidebar.reload
      expect(sidebar.tracker_api_key).to eq('test_api_key')
      expect(sidebar.platform).to eq('psn')
      expect(sidebar.username).to eq('TestPlayer')
      expect(sidebar.show_example_content).to be true
    end
  end

  describe 'All custom sidebars together' do
    it 'can all be active at once' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: {
        active: %w[flickr spotify cod]
      }, xhr: true

      expect(Sidebar.count).to eq(3)
      expect(Sidebar.find_all_visible.length).to eq(3)
    end

    it 'all persist after publish' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: {
        active: %w[flickr spotify cod]
      }, xhr: true

      flickr = Sidebar.find_by(type: 'FlickrSidebar')
      spotify = Sidebar.find_by(type: 'SpotifySidebar')
      cod = Sidebar.find_by(type: 'CodStatsSidebar')

      post '/admin/sidebar/publish', params: {
        configure: {
          flickr.id.to_s => { 'show_example_content' => '1' },
          spotify.id.to_s => { 'show_example_content' => '1' },
          cod.id.to_s => { 'show_example_content' => '1' }
        }
      }

      # Reload page
      get '/admin/sidebar'

      expect(Sidebar.find_all_visible.length).to eq(3)
      expect(Sidebar.find(flickr.id).active_position).not_to be_nil
      expect(Sidebar.find(spotify.id).active_position).not_to be_nil
      expect(Sidebar.find(cod.id).active_position).not_to be_nil
    end

    it 'work with built-in sidebars' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: {
        active: %w[flickr static spotify search cod meta]
      }, xhr: true

      expect(Sidebar.count).to eq(6)

      post '/admin/sidebar/publish', params: {
        configure: Sidebar.all.each_with_object({}) { |s, h| h[s.id.to_s] = {} }
      }

      get '/admin/sidebar'
      expect(Sidebar.find_all_visible.length).to eq(6)
    end
  end

  describe 'Sidebar deletion does not affect others' do
    it 'removing one custom sidebar keeps others' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: {
        active: %w[flickr spotify cod]
      }, xhr: true

      flickr = Sidebar.find_by(type: 'FlickrSidebar')
      Sidebar.find_by(type: 'SpotifySidebar')
      cod = Sidebar.find_by(type: 'CodStatsSidebar')

      # Remove spotify by not including it
      post '/admin/sidebar/set_active', params: {
        active: ["flickr-#{flickr.id}", "cod-#{cod.id}"]
      }, xhr: true

      expect(Sidebar.exists?(flickr.id)).to be true
      expect(Sidebar.exists?(cod.id)).to be true
      expect(Sidebar.find(flickr.id).active_position).not_to be_nil
      expect(Sidebar.find(cod.id).active_position).not_to be_nil
    end
  end

  describe 'Error resilience' do
    it 'handles invalid sidebar type gracefully' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: {
        active: %w[nonexistent flickr]
      }, xhr: true

      # Should only create the valid one
      expect(Sidebar.count).to eq(1)
      expect(Sidebar.first).to be_a(FlickrSidebar)
    end

    it 'does not crash when sidebar config is corrupted' do
      get '/admin/sidebar'
      post '/admin/sidebar/set_active', params: { active: ['flickr'] }, xhr: true
      sidebar = Sidebar.last

      # Corrupt the config
      sidebar.update_column(:config, nil)

      get '/admin/sidebar'
      expect(response).to be_successful
    end
  end
end
