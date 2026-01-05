# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PostType, type: :model do
  before do
    create(:blog)
  end

  describe 'validations' do
    it 'requires name' do
      post_type = PostType.new
      expect(post_type).not_to be_valid
      expect(post_type.errors[:name]).to be_present
    end

    it 'requires unique name' do
      PostType.create!(name: 'video')
      duplicate = PostType.new(name: 'video')
      expect(duplicate).not_to be_valid
    end

    it 'does not allow name "read"' do
      post_type = PostType.new(name: 'read')
      expect(post_type).not_to be_valid
    end
  end

  describe '#sanitize_title' do
    it 'sets permalink from name' do
      post_type = PostType.create!(name: 'Photo Gallery')
      expect(post_type.permalink).to eq('photo-gallery')
    end
  end
end
