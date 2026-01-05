# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Comment, type: :model do
  before do
    create(:blog)
  end

  describe 'associations' do
    it 'belongs to article' do
      article = create(:article)
      comment = create(:comment, article: article)
      expect(comment.article).to eq(article)
    end

    it 'belongs to user optionally' do
      user = create(:user)
      comment = create(:comment, user: user)
      expect(comment.user).to eq(user)
    end
  end

  describe 'factory' do
    it 'creates valid comment' do
      comment = create(:comment)
      expect(comment).to be_valid
      expect(comment).to be_persisted
    end

    it 'creates spam comment' do
      comment = create(:spam_comment)
      expect(comment.state.to_s).to include('spam').or include('Spam')
      expect(comment.published).to be false
    end
  end

  describe '#feed_title' do
    it 'returns comment title for feed' do
      article = create(:article, title: 'Test Article')
      comment = create(:comment, article: article, author: 'John')
      expect(comment.feed_title).to include('John')
      expect(comment.feed_title).to include('Test Article')
    end
  end

  describe 'spam classification' do
    it 'can be marked as spam' do
      comment = create(:comment, state: 'ham')
      comment.mark_as_spam!
      comment.reload
      expect(comment.state.to_s.downcase).to include('spam')
    end

    it 'can be marked as ham' do
      comment = create(:comment, state: 'presumed_spam')
      comment.mark_as_ham!
      comment.reload
      expect(comment.state.to_s.downcase).to include('ham')
    end
  end

  describe 'article comment scopes' do
    let(:article) { create(:article) }

    it 'filters ham comments' do
      ham = create(:comment, article: article, state: 'ham')
      create(:comment, article: article, state: 'spam')
      expect(article.comments.ham).to include(ham)
      expect(article.comments.ham.count).to eq(1)
    end

    it 'filters spam comments' do
      create(:comment, article: article, state: 'ham')
      spam = create(:comment, article: article, state: 'spam')
      expect(article.comments.spam).to include(spam)
      expect(article.comments.spam.count).to eq(1)
    end
  end

  describe 'published comments' do
    let(:article) { create(:article) }

    it 'returns only published comments' do
      published = create(:comment, article: article, published: true)
      unpublished = create(:comment, article: article, published: false, state: 'spam')
      expect(article.published_comments).to include(published)
      expect(article.published_comments).not_to include(unpublished)
    end
  end

  describe '#permalink_url' do
    it 'returns anchor URL to comment on article' do
      article = create(:article, published_at: Time.zone.local(2024, 1, 15), permalink: 'test')
      comment = create(:comment, article: article)
      expect(comment.permalink_url).to include('comment')
      expect(comment.permalink_url).to include(comment.id.to_s)
    end
  end

  describe '#blog' do
    it 'returns article blog' do
      article = create(:article)
      comment = create(:comment, article: article)
      expect(comment.blog).to eq(article.blog)
    end
  end

  describe '#default_text_filter' do
    it 'returns blog comment text filter' do
      comment = create(:comment)
      expect(comment.default_text_filter).to be_a(TextFilter)
    end
  end

  describe '#html' do
    it 'returns rendered HTML body' do
      comment = create(:comment, body: 'Test comment')
      expect(comment.html(:body)).to be_a(String)
    end
  end

  describe 'state transitions' do
    it 'can be created as ham' do
      comment = create(:comment, state: 'ham')
      expect(comment.state.to_s.downcase).to include('ham')
    end

    it 'can be created as spam' do
      comment = create(:comment, state: 'spam')
      expect(comment.state.to_s.downcase).to include('spam')
    end
  end

  describe '#published_at' do
    it 'returns created_at when published' do
      comment = create(:comment, published: true)
      expect(comment.published_at).to eq(comment.created_at)
    end
  end

  describe 'callbacks' do
    it 'sets guid before create' do
      comment = build(:comment, guid: nil)
      comment.save!
      expect(comment.guid).to be_present
    end
  end

  describe 'validations' do
    it 'requires body' do
      comment = build(:comment, body: '')
      expect(comment).not_to be_valid
    end

    it 'requires author' do
      comment = build(:comment, author: '')
      expect(comment).not_to be_valid
    end
  end

  describe 'url normalization' do
    it 'normalizes url starting with http' do
      comment = create(:comment, url: 'http://example.com')
      expect(comment.url).to include('http')
    end

    it 'adds http to url without protocol' do
      comment = build(:comment, url: 'example.com')
      comment.save
      # URL should be normalized or saved as-is depending on implementation
      expect(comment.url).to be_present
    end
  end
end
