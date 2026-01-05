# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tag, type: :model do
  before do
    create(:blog)
  end

  describe 'factory' do
    it 'creates valid tag' do
      tag = create(:tag)
      expect(tag).to be_valid
    end
  end

  describe 'associations' do
    it 'has and belongs to many articles' do
      tag = create(:tag)
      article = create(:article)
      article.tags << tag
      expect(tag.articles).to include(article)
    end
  end

  describe '.get' do
    it 'finds existing tag by name' do
      tag = create(:tag, name: 'ruby')
      expect(Tag.get('ruby')).to eq(tag)
    end

    it 'creates new tag when not found' do
      expect {
        Tag.get('newtag')
      }.to change(Tag, :count).by(1)
    end

    it 'is case insensitive' do
      tag = create(:tag, name: 'ruby')
      expect(Tag.get('Ruby')).to eq(tag)
    end
  end

  describe '.find_by_permalink' do
    it 'finds tag by permalink' do
      tag = create(:tag, name: 'ruby')
      expect(Tag.find_by_permalink('ruby')).to eq(tag)
    end

    it 'returns nil for non-existent tag' do
      expect(Tag.find_by_permalink('nonexistent')).to be_nil
    end
  end

  describe '.find_by_name_or_display_name' do
    it 'finds by name' do
      tag = create(:tag, name: 'ruby', display_name: 'Ruby')
      expect(Tag.find_by_name_or_display_name('ruby', 'ruby')).to eq(tag)
    end

    it 'finds by display_name' do
      tag = create(:tag, name: 'ruby', display_name: 'Ruby Lang')
      expect(Tag.find_by_name_or_display_name('ruby', 'Ruby Lang')).to eq(tag)
    end
  end

  describe '#to_param' do
    it 'returns permalink' do
      tag = create(:tag, name: 'ruby')
      expect(tag.to_param).to eq('ruby')
    end
  end

  describe '#published_articles' do
    it 'returns only published articles' do
      tag = create(:tag)
      published = create(:article, published: true, published_at: 1.day.ago)
      unpublished = create(:unpublished_article)
      published.tags << tag
      unpublished.tags << tag
      expect(tag.published_articles).to include(published)
      expect(tag.published_articles).not_to include(unpublished)
    end
  end

  describe '.merge' do
    it 'updates join table to transfer articles from one tag to another' do
      tag1 = create(:tag, name: 'ruby')
      tag2 = create(:tag, name: 'rubycode')
      article = create(:article)

      # Add article to tag2 via direct SQL to avoid callbacks
      ActiveRecord::Base.connection.execute(
        "INSERT INTO articles_tags (article_id, tag_id) VALUES (#{article.id}, #{tag2.id})"
      )

      # Verify article is on tag2
      count_before = ActiveRecord::Base.connection.select_value(
        "SELECT COUNT(*) FROM articles_tags WHERE tag_id = #{tag2.id}"
      )
      expect(count_before.to_i).to eq(1)

      # Merge tag2 into tag1
      Tag.merge(tag2.id, tag1.id)

      # Verify article is now on tag1
      count_after = ActiveRecord::Base.connection.select_value(
        "SELECT COUNT(*) FROM articles_tags WHERE tag_id = #{tag1.id}"
      )
      expect(count_after.to_i).to eq(1)

      # Verify tag2 has no articles
      count_tag2 = ActiveRecord::Base.connection.select_value(
        "SELECT COUNT(*) FROM articles_tags WHERE tag_id = #{tag2.id}"
      )
      expect(count_tag2.to_i).to eq(0)
    end
  end

  describe '.find_with_char' do
    it 'finds tags starting with character' do
      create(:tag, name: 'ruby')
      create(:tag, name: 'rails')
      create(:tag, name: 'python')
      tags = Tag.find_with_char('r')
      expect(tags.map(&:name)).to include('ruby', 'rails')
      expect(tags.map(&:name)).not_to include('python')
    end
  end

  describe '.collection_to_string' do
    it 'converts tags to comma separated string' do
      tag1 = create(:tag, name: 'ruby')
      tag2 = create(:tag, name: 'rails')
      result = Tag.collection_to_string([tag1, tag2])
      expect(result).to include('ruby')
      expect(result).to include('rails')
    end
  end

  describe '.find_all_with_article_counters' do
    it 'returns tags with article counts' do
      tag = create(:tag)
      article = create(:article, published: true, published_at: 1.day.ago)
      article.tags << tag
      results = Tag.find_all_with_article_counters
      tag_result = results.find { |t| t.id == tag.id }
      expect(tag_result).to be_present
    end
  end

  describe '#ensure_naming_conventions' do
    it 'converts name to URL format on save' do
      tag = Tag.new(display_name: 'Ruby Programming')
      tag.save
      expect(tag.name).to eq('ruby-programming')
    end

    it 'sets display_name from name if blank' do
      tag = Tag.new(name: 'ruby')
      tag.save
      expect(tag.display_name).to eq('ruby')
    end
  end
end
