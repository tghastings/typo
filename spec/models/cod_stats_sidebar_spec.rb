require 'spec_helper'

describe CodStatsSidebar do
  before(:each) do
    @sidebar = CodStatsSidebar.new
  end

  describe "class definition" do
    it "should inherit from Sidebar" do
      expect(CodStatsSidebar.superclass).to eq(Sidebar)
    end

    it "should have correct display_name" do
      expect(CodStatsSidebar.display_name).to eq('Call of Duty Stats')
    end

    it "should have correct description" do
      expect(CodStatsSidebar.description).to eq('Display your Call of Duty stats from COD Tracker')
    end
  end

  describe "default settings" do
    it "should be valid" do
      expect(@sidebar).to be_valid
    end

    it "title should default to 'CoD Stats'" do
      expect(@sidebar.title).to eq('CoD Stats')
    end

    it "tracker_api_key should default to empty string" do
      expect(@sidebar.tracker_api_key).to eq('')
    end

    it "platform should default to 'battlenet'" do
      expect(@sidebar.platform).to eq('battlenet')
    end

    it "username should default to empty string" do
      expect(@sidebar.username).to eq('')
    end

    it "game should default to 'mw2'" do
      expect(@sidebar.game).to eq('mw2')
    end

    it "show_example_content should default to false" do
      expect(@sidebar.show_example_content).to eq(false)
    end
  end

  describe "content partial" do
    it "should have correct content partial path" do
      expect(@sidebar.content_partial).to eq('/cod_stats_sidebar/content')
    end
  end

  describe "#configured?" do
    it "should return false when credentials are blank" do
      expect(@sidebar.configured?).to be false
    end

    it "should return true when api key and username are present" do
      @sidebar.tracker_api_key = 'test_key'
      @sidebar.username = 'TestPlayer'
      expect(@sidebar.configured?).to be true
    end
  end

  describe "#stats" do
    context "when not configured and show_example_content is false" do
      it "should return nil" do
        expect(@sidebar.stats).to be_nil
      end
    end

    context "when show_example_content is true" do
      before { @sidebar.show_example_content = true }

      it "should return example stats" do
        data = @sidebar.stats
        expect(data).to be_a(Hash)
        expect(data['platformInfo']).to be_present
        expect(data['segments']).to be_an(Array)
      end

      it "should include overview stats" do
        data = @sidebar.stats
        overview = data['segments'].find { |s| s['type'] == 'overview' }
        expect(overview).to be_present
        expect(overview['stats']['kills']).to be_present
        expect(overview['stats']['kdRatio']).to be_present
      end
    end
  end

  describe "#format_stat" do
    it "should format millions correctly" do
      expect(@sidebar.format_stat(1_500_000)).to eq('1.5M')
    end

    it "should format thousands correctly" do
      expect(@sidebar.format_stat(1_500)).to eq('1.5K')
    end

    it "should return plain number for small values" do
      expect(@sidebar.format_stat(500)).to eq('500')
    end

    it "should return dash for nil values" do
      expect(@sidebar.format_stat(nil)).to eq('—')
    end
  end

  describe "database persistence" do
    it "should save and reload correctly" do
      @sidebar.title = 'My CoD Stats'
      @sidebar.tracker_api_key = 'abc123'
      @sidebar.username = 'Player1'
      @sidebar.platform = 'psn'
      @sidebar.active_position = 1
      @sidebar.save!

      reloaded = Sidebar.find(@sidebar.id)
      expect(reloaded).to be_a(CodStatsSidebar)
      expect(reloaded.title).to eq('My CoD Stats')
      expect(reloaded.tracker_api_key).to eq('abc123')
      expect(reloaded.username).to eq('Player1')
      expect(reloaded.platform).to eq('psn')
    end
  end

  describe "compatibility with other sidebars" do
    it "should coexist with FlickrSidebar and SpotifySidebar" do
      cod = CodStatsSidebar.create!(active_position: 1)
      flickr = FlickrSidebar.create!(active_position: 2)
      spotify = SpotifySidebar.create!(active_position: 3)

      visible = Sidebar.find_all_visible
      expect(visible.length).to eq(3)
      expect(visible.map(&:class)).to include(CodStatsSidebar, FlickrSidebar, SpotifySidebar)
    end

    it "should coexist with built-in sidebars" do
      cod = CodStatsSidebar.create!(active_position: 1)
      static = StaticSidebar.create!(active_position: 2)
      search = SearchSidebar.create!(active_position: 3)
      meta = MetaSidebar.create!(active_position: 4)

      visible = Sidebar.find_all_visible
      expect(visible.length).to eq(4)
      expect(visible[0]).to be_a(CodStatsSidebar)
    end
  end
end
