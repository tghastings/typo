# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationMailer, type: :mailer do
  before do
    create(:blog)
  end

  let(:user) { create(:user, email: 'test@example.com') }
  let(:article) { create(:article, published: true, published_at: 1.day.ago) }

  describe '.article' do
    it 'creates an article notification email' do
      mail = NotificationMailer.article(article, user)
      expect(mail.to).to include(user.email)
      expect(mail.subject).to include(article.title)
    end
  end

  describe '.comment' do
    let(:comment) { create(:comment, article: article, author: 'Test', body: 'Great post!') }

    it 'creates a comment notification email' do
      mail = NotificationMailer.comment(comment, user)
      expect(mail.to).to include(user.email)
      expect(mail.subject).to include(article.title)
    end
  end

  describe '.trackback' do
    let(:trackback) { create(:trackback, article: article, blog_name: 'Other Blog', title: 'Trackback') }

    it 'creates a trackback notification email' do
      mail = NotificationMailer.trackback(trackback, user)
      expect(mail.to).to include(user.email)
      expect(mail.subject).to include(article.title)
    end
  end

  describe '.notif_user' do
    it 'creates a user notification email' do
      mail = NotificationMailer.notif_user(user)
      expect(mail.to).to include(user.email)
    end
  end
end
