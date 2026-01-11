# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resource, type: :model do
  before do
    create(:blog)
  end

  describe 'factory' do
    it 'creates valid resource' do
      resource = create(:resource)
      expect(resource).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to article optionally' do
      article = create(:article)
      resource = create(:resource, article: article)
      expect(resource.article).to eq(article)
    end
  end

  describe 'scopes' do
    describe '.images' do
      it 'returns only image resources' do
        image = create(:resource, mime: 'image/jpeg')
        create(:resource, mime: 'application/pdf')
        expect(Resource.images).to include(image)
        expect(Resource.images.count).to eq(1)
      end
    end

    describe '.without_images' do
      it 'returns non-image resources' do
        create(:resource, mime: 'image/jpeg')
        pdf = create(:resource, mime: 'application/pdf')
        expect(Resource.without_images).to include(pdf)
        expect(Resource.without_images.count).to eq(1)
      end
    end

    describe '.by_filename' do
      it 'orders by filename' do
        create(:resource, filename: 'z_file.jpg')
        create(:resource, filename: 'a_file.jpg')
        expect(Resource.by_filename.first.filename).to eq('a_file.jpg')
      end
    end

    describe '.by_created_at' do
      it 'orders by created_at descending' do
        create(:resource, created_at: 2.days.ago)
        new = create(:resource, created_at: 1.day.ago)
        expect(Resource.by_created_at.first).to eq(new)
      end
    end
  end

  describe '#url' do
    it 'returns nil when file is not attached' do
      resource = create(:resource, filename: 'test.jpg')
      expect(resource.url).to be_nil
    end

    it 'returns resource URL when file is attached' do
      resource = create(:resource, filename: 'test.jpg')
      resource.file.attach(
        io: StringIO.new('test file content'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      )
      expect(resource.url).to be_present
    end
  end

  describe '#file_exists?' do
    it 'returns false when file is not attached' do
      resource = create(:resource)
      expect(resource.file_exists?).to be false
    end

    it 'returns true when file is attached' do
      resource = create(:resource)
      resource.file.attach(
        io: StringIO.new('test file content'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      )
      expect(resource.file_exists?).to be true
    end
  end
end
