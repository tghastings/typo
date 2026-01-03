require 'spec_helper'

describe FlickrSidebar do
  before(:each) do
    @sidebar = FlickrSidebar.new
  end

  describe "class definition" do
    it "should inherit from Sidebar" do
      expect(FlickrSidebar.superclass).to eq(Sidebar)
    end

    it "should have correct display_name" do
      expect(FlickrSidebar.display_name).to eq('Flickr Photos')
    end

    it "should have correct description" do
      expect(FlickrSidebar.description).to eq('Display your recent photos from Flickr')
    end
  end

  describe "default settings" do
    it "should be valid" do
      expect(@sidebar).to be_valid
    end

    it "title should default to 'Photos'" do
      expect(@sidebar.title).to eq('Photos')
    end

    it "flickr_user_id should default to empty string" do
      expect(@sidebar.flickr_user_id).to eq('')
    end

    it "photo_count should default to '6'" do
      expect(@sidebar.photo_count).to eq('6')
    end

    it "photo_size should default to 'square'" do
      expect(@sidebar.photo_size).to eq('square')
    end

    it "show_example_content should default to false" do
      expect(@sidebar.show_example_content).to eq(false)
    end
  end

  describe "content partial" do
    it "should have correct content partial path" do
      expect(@sidebar.content_partial).to eq('/flickr_sidebar/content')
    end
  end

  describe "#photos" do
    context "when flickr_user_id is blank and show_example_content is false" do
      it "should return empty array" do
        expect(@sidebar.photos).to eq([])
      end
    end

    context "when show_example_content is true" do
      before { @sidebar.show_example_content = true }

      it "should return example photos" do
        photos = @sidebar.photos
        expect(photos).to be_an(Array)
        expect(photos.length).to be > 0
        expect(photos.first).to respond_to(:title)
        expect(photos.first).to respond_to(:id)
      end
    end

    context "when flickr_user_id is set but API fails" do
      before do
        @sidebar.flickr_user_id = '12345678@N00'
        # Simulate API failure
        allow(FlickRaw).to receive(:api_key=)
        allow_any_instance_of(FlickrSidebar).to receive(:flickr).and_raise(StandardError.new("API Error"))
      end

      it "should return empty array on API error" do
        photos = @sidebar.photos
        expect(photos).to eq([])
      end
    end
  end

  describe "database persistence" do
    it "should save and reload correctly" do
      @sidebar.title = 'My Flickr'
      @sidebar.flickr_user_id = '99999@N00'
      @sidebar.active_position = 1
      @sidebar.save!

      reloaded = Sidebar.find(@sidebar.id)
      expect(reloaded).to be_a(FlickrSidebar)
      expect(reloaded.title).to eq('My Flickr')
      expect(reloaded.flickr_user_id).to eq('99999@N00')
    end
  end

  describe "compatibility with other sidebars" do
    it "should coexist with other sidebar types" do
      # Create multiple sidebar types
      flickr = FlickrSidebar.create!(active_position: 1)
      static = StaticSidebar.create!(active_position: 2)
      search = SearchSidebar.create!(active_position: 3)

      visible = Sidebar.find_all_visible
      expect(visible.length).to eq(3)
      expect(visible[0]).to be_a(FlickrSidebar)
      expect(visible[1]).to be_a(StaticSidebar)
      expect(visible[2]).to be_a(SearchSidebar)
    end
  end
end
