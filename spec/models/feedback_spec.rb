require 'spec_helper'

describe Feedback do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:user) { FactoryBot.create(:user) }
  let!(:article) { FactoryBot.create(:article, user: user) }

  describe '.default_order' do
    it 'returns created_at ASC' do
      expect(Feedback.default_order).to eq('created_at ASC')
    end
  end

  describe '#parent' do
    it 'returns the article' do
      comment = FactoryBot.create(:comment, article: article)
      expect(comment.parent).to eq(article)
    end
  end

  describe '#correct_url' do
    it 'prepends http:// to url without protocol' do
      comment = FactoryBot.build(:comment, article: article, url: 'example.com')
      comment.save
      expect(comment.url).to eq('http://example.com')
    end

    it 'leaves url with http:// unchanged' do
      comment = FactoryBot.build(:comment, article: article, url: 'http://example.com')
      comment.save
      expect(comment.url).to eq('http://example.com')
    end

    it 'leaves url with https:// unchanged' do
      comment = FactoryBot.build(:comment, article: article, url: 'https://example.com')
      comment.save
      expect(comment.url).to eq('https://example.com')
    end

    it 'handles blank url' do
      comment = FactoryBot.build(:comment, article: article, url: '')
      comment.save
      expect(comment.url).to eq('')
    end
  end

  describe '#akismet_options' do
    it 'returns hash with comment info' do
      comment = FactoryBot.build(:comment,
        article: article,
        ip: '127.0.0.1',
        author: 'Test Author',
        email: 'test@example.com',
        url: 'http://example.com',
        body: 'Test comment')

      options = comment.akismet_options
      expect(options[:user_ip]).to eq('127.0.0.1')
      expect(options[:comment_type]).to eq('comment')
      expect(options[:comment_author_email]).to eq('test@example.com')
      expect(options[:comment_author_url]).to eq('http://example.com')
      expect(options[:comment_content]).to eq('Test comment')
    end
  end

  describe '#spam_fields' do
    it 'returns array of spam-checkable fields' do
      comment = FactoryBot.build(:comment, article: article)
      expect(comment.spam_fields).to eq([:title, :body, :ip, :url])
    end
  end

  describe '#classify' do
    it 'returns :ham for comments from logged-in users' do
      comment = FactoryBot.build(:comment, article: article, user: user)
      expect(comment.classify).to eq(:ham)
    end
  end

  describe '#mark_as_ham!' do
    it 'marks feedback as ham and saves' do
      comment = FactoryBot.create(:comment, article: article)
      comment.mark_as_ham!
      comment.reload
      expect(comment.ham?).to be true
    end
  end

  describe '#mark_as_spam!' do
    it 'marks feedback as spam and saves' do
      comment = FactoryBot.create(:comment, article: article)
      comment.mark_as_spam!
      comment.reload
      expect(comment.spam?).to be true
    end
  end

  describe '#withdraw!' do
    it 'withdraws the feedback' do
      comment = FactoryBot.create(:comment, article: article)
      comment.mark_as_ham!
      comment.confirm_classification!
      comment.withdraw!
      comment.reload
      expect(comment.published?).to be false
    end
  end

  describe '#blog_allows_feedback?' do
    it 'returns true by default' do
      comment = FactoryBot.build(:comment, article: article)
      expect(comment.blog_allows_feedback?).to be true
    end
  end

  describe '#html_postprocess' do
    it 'sanitizes and auto-links html' do
      comment = FactoryBot.build(:comment, article: article)
      result = comment.html_postprocess(:body, '<p>Visit http://example.com</p>')
      expect(result).to include('href')
      expect(result).to include('nofollow')
    end
  end

  describe '#permalink_url' do
    it 'returns url with anchor' do
      comment = FactoryBot.create(:comment, article: article)
      url = comment.permalink_url
      expect(url).to include(article.permalink_url)
    end
  end

  describe '#edit_url' do
    it 'returns admin edit url' do
      comment = FactoryBot.create(:comment, article: article)
      url = comment.edit_url
      expect(url).to include('admin/comments/edit')
    end
  end

  describe '#delete_url' do
    it 'returns admin delete url' do
      comment = FactoryBot.create(:comment, article: article)
      url = comment.delete_url
      expect(url).to include('admin/comments/destroy')
    end
  end
end
