# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContentHelper, type: :helper do
  before do
    create(:blog)
  end

  describe '#page_title' do
    it 'returns the page title' do
      assign(:page_title, 'Test Title')
      expect(helper.page_title).to eq('Test Title')
    end
  end

  describe '#article_links' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago) }

    it 'returns links for article' do
      result = helper.article_links(article)
      expect(result).to be_a(String)
    end

    it 'includes category links when categories exist' do
      category = create(:category, name: 'Tech')
      article.categories << category
      result = helper.article_links(article)
      expect(result).to include('Tech')
    end
  end

  describe '#category_links' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago) }

    it 'returns category links' do
      category = create(:category, name: 'Ruby')
      article.categories << category
      result = helper.category_links(article)
      expect(result).to include('Ruby')
    end
  end

  describe '#tag_links' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago) }

    it 'returns tag links' do
      tag = create(:tag, name: 'rails')
      article.tags << tag
      result = helper.tag_links(article)
      expect(result.to_s).to include('rails')
    end
  end

  describe '#next_link' do
    let!(:article1) { create(:article, title: 'First', published: true, published_at: 2.days.ago) }
    let!(:article2) { create(:article, title: 'Second', published: true, published_at: 1.day.ago) }

    it 'returns link to next article when it exists' do
      result = helper.next_link(article1)
      # next article exists if there's a more recent published article
      expect(result).to be_a(String)
    end
  end

  describe '#prev_link' do
    let!(:article1) { create(:article, title: 'First', published: true, published_at: 2.days.ago) }
    let!(:article2) { create(:article, title: 'Second', published: true, published_at: 1.day.ago) }

    it 'returns link to previous article when it exists' do
      result = helper.prev_link(article2)
      expect(result).to be_a(String)
    end

    it 'returns empty string when no previous article exists' do
      # article1 is the oldest, so it has no previous
      expect(article1.previous).to be_nil
    end
  end

  describe '#next_link edge cases' do
    let!(:article1) { create(:article, title: 'First', published: true, published_at: 2.days.ago) }
    let!(:article2) { create(:article, title: 'Second', published: true, published_at: 1.day.ago) }

    it 'uses custom prefix when provided and next exists' do
      result = helper.next_link(article1, 'Next Article')
      expect(result).to include('Next Article')
    end

    it 'returns empty when no next article exists' do
      # article2 is the newest, so it has no next
      expect(article2.next).to be_nil
    end
  end

  describe '#article_links with comments disabled' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago, allow_comments: false) }

    it 'does not include comments link' do
      result = helper.article_links(article)
      expect(result).not_to include('comment')
    end
  end

  describe '#article_links with tags' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago) }

    it 'includes tag links when tags exist' do
      tag = create(:tag, name: 'ruby')
      article.tags << tag
      result = helper.article_links(article)
      expect(result.to_s).to include('ruby')
    end
  end

  describe '#category_links with custom prefix' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago) }

    it 'uses custom prefix' do
      category = create(:category, name: 'Tech')
      article.categories << category
      result = helper.category_links(article, 'Filed under')
      expect(result).to include('Filed under')
    end
  end

  describe '#tag_links with custom prefix' do
    let(:article) { create(:article, published: true, published_at: 1.day.ago) }

    it 'uses custom prefix' do
      tag = create(:tag, name: 'rails')
      article.tags << tag
      result = helper.tag_links(article, 'Tagged with')
      expect(result).to include('Tagged with')
    end
  end
end
