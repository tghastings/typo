# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Content, type: :model do
  before do
    create(:blog)
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published content' do
        published = create(:article, published: true, published_at: 1.day.ago)
        create(:article, published: false)
        expect(Content.published).to include(published)
      end
    end

    describe '.not_published' do
      it 'returns only unpublished content' do
        create(:article, published: true, published_at: 1.day.ago)
        unpublished = create(:article, published: false)
        expect(Content.not_published).to include(unpublished)
      end
    end

    describe '.draft' do
      it 'returns only draft content' do
        draft = create(:article, state: 'draft')
        create(:article, state: 'published')
        expect(Content.draft).to include(draft)
      end
    end

    describe '.already_published' do
      it 'returns content published before now' do
        published = create(:article, published: true, published_at: 1.day.ago)
        future = create(:article, published: true, published_at: 1.day.from_now)
        expect(Content.already_published).to include(published)
        expect(Content.already_published).not_to include(future)
      end
    end

    describe '.published_at_like' do
      before do
        @article2024 = create(:article, published: true, published_at: Time.zone.local(2024, 6, 15, 12, 0, 0))
        @article2023 = create(:article, published: true, published_at: Time.zone.local(2023, 3, 10, 12, 0, 0))
      end

      it 'filters by year-month-day' do
        result = Content.published_at_like('2024-06-15')
        expect(result).to include(@article2024)
        expect(result).not_to include(@article2023)
      end

      it 'filters by year-month' do
        result = Content.published_at_like('2024-06')
        expect(result).to include(@article2024)
        expect(result).not_to include(@article2023)
      end

      it 'filters by year' do
        result = Content.published_at_like('2024')
        expect(result).to include(@article2024)
        expect(result).not_to include(@article2023)
      end
    end

    describe '.user_id' do
      it 'returns content by specific user' do
        user1 = create(:user)
        user2 = create(:user)
        article1 = create(:article, user: user1)
        create(:article, user: user2)
        expect(Content.user_id(user1.id)).to include(article1)
      end
    end

    describe '.searchstring' do
      before do
        @match = create(:article, title: 'Ruby Programming', body: 'Learn Ruby', state: 'published')
        @no_match = create(:article, title: 'Python Programming', body: 'Learn Python', state: 'published')
      end

      it 'searches title' do
        result = Content.searchstring('ruby')
        expect(result).to include(@match)
        expect(result).not_to include(@no_match)
      end
    end
  end

  describe '#invalidates_cache?' do
    it 'returns true for published content with changes' do
      article = create(:article, published: true, published_at: 1.day.ago)
      article.title = 'Updated Title'
      article.save
      expect(article.invalidates_cache?).to be true
    end
  end

  describe '#text_filter' do
    it 'returns text filter when set' do
      text_filter = create(:markdown)
      article = create(:article)
      article.text_filter_id = text_filter.id
      expect(article.text_filter).to eq(text_filter)
    end

    it 'returns default when no text filter set' do
      article = create(:article)
      article.text_filter_id = nil
      expect(article.text_filter).to be_present
    end
  end

  describe '#default_text_filter' do
    it 'returns blog text filter' do
      article = Article.new
      expect(article.default_text_filter).to be_present
    end
  end

  describe '#blog' do
    it 'returns the blog' do
      article = create(:article)
      expect(article.blog).to eq(Blog.first)
    end
  end
end
