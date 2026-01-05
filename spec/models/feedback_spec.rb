# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feedback, type: :model do
  before do
    create(:blog)
  end

  let(:article) { create(:article, published: true, published_at: 1.day.ago) }

  describe '.default_order' do
    it 'returns created_at ASC' do
      expect(Feedback.default_order).to eq('created_at ASC')
    end
  end

  describe '#parent' do
    it 'returns the article' do
      comment = create(:comment, article: article)
      expect(comment.parent).to eq(article)
    end
  end

  describe '#correct_url' do
    it 'adds http:// to URLs without protocol' do
      comment = build(:comment, article: article, url: 'example.com')
      comment.valid?
      comment.save
      expect(comment.url).to eq('http://example.com')
    end

    it 'leaves URLs with http:// unchanged' do
      comment = build(:comment, article: article, url: 'http://example.com')
      comment.save
      expect(comment.url).to eq('http://example.com')
    end

    it 'leaves URLs with https:// unchanged' do
      comment = build(:comment, article: article, url: 'https://example.com')
      comment.save
      expect(comment.url).to eq('https://example.com')
    end
  end

  describe '#blog_allows_feedback?' do
    it 'returns true by default' do
      comment = build(:comment, article: article)
      expect(comment.blog_allows_feedback?).to be true
    end
  end

  describe '#akismet_options' do
    it 'returns hash with spam check options' do
      comment = build(:comment, article: article, ip: '127.0.0.1', author: 'Test')
      options = comment.akismet_options
      expect(options).to include(:user_ip, :comment_type, :comment_author)
    end
  end

  describe '#spam_fields' do
    it 'returns array of fields to check' do
      comment = build(:comment, article: article)
      expect(comment.spam_fields).to include(:title, :body, :ip, :url)
    end
  end

  describe '#mark_as_ham!' do
    it 'marks feedback as ham and saves' do
      comment = create(:comment, article: article, state: 'presumed_spam')
      comment.mark_as_ham!
      comment.reload
      expect(comment.state.to_s).to match(/ham/i)
    end
  end

  describe '#mark_as_spam!' do
    it 'marks feedback as spam' do
      comment = create(:comment, article: article, state: 'ham')
      comment.mark_as_spam!
      comment.reload
      expect(comment.state.to_s).to match(/spam/i)
    end
  end

  describe '#withdraw!' do
    it 'withdraws the feedback' do
      comment = create(:comment, article: article)
      comment.withdraw!
      comment.reload
      expect(comment.state.to_s).to match(/spam/i)
    end
  end

  describe '#permalink_url' do
    it 'returns URL with anchor' do
      comment = create(:comment, article: article)
      url = comment.permalink_url
      expect(url).to include("comment-#{comment.id}")
    end
  end

  describe '#edit_url' do
    it 'returns admin edit URL' do
      comment = create(:comment, article: article)
      url = comment.edit_url
      expect(url).to include('admin')
      expect(url).to include('edit')
    end
  end

  describe '#delete_url' do
    it 'returns admin delete URL' do
      comment = create(:comment, article: article)
      url = comment.delete_url
      expect(url).to include('admin')
      expect(url).to include('destroy')
    end
  end
end
