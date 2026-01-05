# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trackback, type: :model do
  before do
    create(:blog)
  end

  describe 'factory' do
    it 'creates valid trackback' do
      trackback = create(:trackback)
      expect(trackback).to be_valid
      expect(trackback).to be_persisted
    end
  end

  describe 'associations' do
    it 'belongs to article' do
      article = create(:article)
      trackback = create(:trackback, article: article)
      expect(trackback.article).to eq(article)
    end
  end

  describe '#feed_title' do
    it 'returns trackback title for feed' do
      article = create(:article, title: 'Test Article')
      trackback = create(:trackback, article: article, blog_name: 'External Blog')
      expect(trackback.feed_title).to include('External Blog')
      expect(trackback.feed_title).to include('Test Article')
    end
  end

  describe 'published trackbacks' do
    let(:article) { create(:article) }

    it 'returns only published trackbacks' do
      published = create(:trackback, article: article, published: true, state: 'ham')
      unpublished = create(:trackback, article: article, state: 'spam', published: false)
      expect(article.published_trackbacks).to include(published)
      expect(article.published_trackbacks).not_to include(unpublished)
    end
  end
end
