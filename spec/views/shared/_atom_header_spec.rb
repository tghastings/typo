require 'spec_helper'

describe "shared/_atom_header.atom.builder" do
  before do
    stub_default_blog
  end

  describe "with no items" do
    before do
      require 'builder'
      @xml = ::Builder::XmlMarkup.new
      @xml.foo do
        render :partial => "shared/atom_header",
          :formats => [:atom],
          :locals => { :feed => @xml, :items => [] }
      end
    end

    it "shows typo with the current version as the generator" do
      xml = Nokogiri::XML.parse(@xml.target!)
      generator = xml.css("generator").first
      expect(generator).not_to be_nil
      generator.content.should eq("Typo")
      generator["version"].should == TYPO_VERSION
    end
  end
end


