# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Category, type: :model do
  before do
    create(:blog)
  end

  describe 'validations' do
    it 'creates valid category' do
      category = create(:category)
      expect(category).to be_valid
    end
  end

  describe 'associations' do
    it 'has many articles through categorizations' do
      category = create(:category)
      article = create(:article)
      article.categories << category
      expect(category.articles).to include(article)
    end

    it 'has many categorizations' do
      category = create(:category)
      article = create(:article)
      article.categories << category
      expect(category.categorizations.count).to eq(1)
    end

    it 'can have parent category' do
      parent = create(:category, name: 'Parent')
      child = create(:category, name: 'Child', parent: parent)
      expect(child.parent).to eq(parent)
    end

    it 'can have child categories' do
      parent = create(:category, name: 'Parent')
      child = create(:category, name: 'Child', parent: parent)
      expect(parent.children).to include(child)
    end
  end

  describe '#set_permalink' do
    it 'sets permalink from name when blank' do
      category = Category.new(name: 'My Category', permalink: nil)
      category.save
      expect(category.permalink).to eq('my-category')
    end

    it 'does not override existing permalink' do
      category = Category.new(name: 'My Category', permalink: 'custom-link')
      category.save
      expect(category.permalink).to eq('custom-link')
    end
  end

  describe '.find_by_permalink' do
    it 'finds category by permalink' do
      category = create(:category, permalink: 'tech')
      expect(Category.find_by_permalink('tech')).to eq(category)
    end

    it 'raises RecordNotFound for non-existent category' do
      expect {
        Category.find_by_permalink('nonexistent')
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#display_name' do
    it 'returns name' do
      category = create(:category, name: 'Technology')
      expect(category.display_name).to eq('Technology')
    end
  end

  describe '#permalink_url' do
    it 'returns category URL' do
      category = create(:category, permalink: 'tech')
      url = category.permalink_url
      expect(url).to include('category')
      expect(url).to include('tech')
    end
  end

  describe '#published_articles' do
    it 'returns only published articles' do
      category = create(:category)
      published = create(:article, published: true, published_at: 1.day.ago)
      unpublished = create(:unpublished_article)
      category.articles << published
      category.articles << unpublished
      expect(category.published_articles).to include(published)
      expect(category.published_articles).not_to include(unpublished)
    end
  end

  describe '.reorder' do
    it 'reorders categories by position list' do
      cat1 = create(:category, position: 1)
      cat2 = create(:category, position: 2)
      cat3 = create(:category, position: 3)
      Category.reorder([cat3.id, cat1.id, cat2.id])
      expect(cat3.reload.position).to eq(0)
      expect(cat1.reload.position).to eq(1)
      expect(cat2.reload.position).to eq(2)
    end
  end

  describe '.reorder_alpha' do
    it 'reorders categories alphabetically' do
      create(:category, name: 'Zebra', position: 1)
      create(:category, name: 'Apple', position: 2)
      create(:category, name: 'Mango', position: 3)
      Category.reorder_alpha
      expect(Category.order(:position).first.name).to eq('Apple')
    end
  end

  describe '.find_all_with_article_counters' do
    it 'returns categories with article counts' do
      category = create(:category)
      article = create(:article, published: true, published_at: 1.day.ago)
      article.categories << category
      results = Category.find_all_with_article_counters
      cat_result = results.find { |c| c.id == category.id }
      expect(cat_result).to be_present
    end
  end

  describe 'default ordering' do
    it 'orders by name ascending' do
      create(:category, name: 'Zebra')
      create(:category, name: 'Apple')
      categories = Category.all
      expect(categories.first.name).to eq('Apple')
    end
  end
end
