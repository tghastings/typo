# frozen_string_literal: true

require 'spec_helper'

describe SpotifySidebar do
  before(:each) do
    @sidebar = SpotifySidebar.new
  end

  describe 'class definition' do
    it 'should inherit from Sidebar' do
      expect(SpotifySidebar.superclass).to eq(Sidebar)
    end

    it 'should have correct display_name' do
      expect(SpotifySidebar.display_name).to eq('Spotify')
    end

    it 'should have correct description' do
      expect(SpotifySidebar.description).to eq('Display your recently played tracks or now playing from Spotify')
    end
  end

  describe 'default settings' do
    it 'should be valid' do
      expect(@sidebar).to be_valid
    end

    it "title should default to 'Now Playing'" do
      expect(@sidebar.title).to eq('Now Playing')
    end

    it 'client_id should default to empty string' do
      expect(@sidebar.client_id).to eq('')
    end

    it 'client_secret should default to empty string' do
      expect(@sidebar.client_secret).to eq('')
    end

    it 'refresh_token should default to empty string' do
      expect(@sidebar.refresh_token).to eq('')
    end

    it "display_count should default to '5'" do
      expect(@sidebar.display_count).to eq('5')
    end

    it 'show_example_content should default to false' do
      expect(@sidebar.show_example_content).to eq(false)
    end
  end

  describe 'content partial' do
    it 'should have correct content partial path' do
      expect(@sidebar.content_partial).to eq('/spotify_sidebar/content')
    end
  end

  describe '#configured?' do
    it 'should return false when credentials are blank' do
      expect(@sidebar.configured?).to be false
    end

    it 'should return true when all credentials are present' do
      @sidebar.client_id = 'test_id'
      @sidebar.client_secret = 'test_secret'
      @sidebar.refresh_token = 'test_token'
      expect(@sidebar.configured?).to be true
    end
  end

  describe '#recently_played' do
    context 'when not configured and show_example_content is false' do
      it 'should return empty array' do
        expect(@sidebar.recently_played).to eq([])
      end
    end

    context 'when show_example_content is true' do
      before { @sidebar.show_example_content = true }

      it 'should return example tracks' do
        tracks = @sidebar.recently_played
        expect(tracks).to be_an(Array)
        expect(tracks.length).to be > 0
        expect(tracks.first['track']['name']).to be_present
        expect(tracks.first['track']['artists']).to be_an(Array)
      end
    end
  end

  describe '#now_playing' do
    context 'when show_example_content is true' do
      before { @sidebar.show_example_content = true }

      it 'should return example now playing data' do
        now = @sidebar.now_playing
        expect(now).to be_a(Hash)
        expect(now['is_playing']).to eq(true)
        expect(now['item']['name']).to be_present
      end
    end
  end

  describe 'database persistence' do
    it 'should save and reload correctly' do
      @sidebar.title = 'My Music'
      @sidebar.client_id = 'abc123'
      @sidebar.active_position = 1
      @sidebar.save!

      reloaded = Sidebar.find(@sidebar.id)
      expect(reloaded).to be_a(SpotifySidebar)
      expect(reloaded.title).to eq('My Music')
      expect(reloaded.client_id).to eq('abc123')
    end
  end

  describe 'compatibility with other sidebars' do
    it 'should coexist with FlickrSidebar' do
      SpotifySidebar.create!(active_position: 1)
      FlickrSidebar.create!(active_position: 2)

      visible = Sidebar.find_all_visible
      expect(visible.length).to eq(2)
      expect(visible.map(&:class)).to include(SpotifySidebar, FlickrSidebar)
    end
  end
end
