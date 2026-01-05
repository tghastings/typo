# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notification, type: :model do
  before do
    create(:blog)
  end

  describe 'associations' do
    it 'belongs to notify_content' do
      user = create(:user)
      article = create(:article)
      notification = Notification.create!(notify_user: user, notify_content: article)
      expect(notification.notify_content).to eq(article)
    end

    it 'belongs to notify_user' do
      user = create(:user)
      article = create(:article)
      notification = Notification.create!(notify_user: user, notify_content: article)
      expect(notification.notify_user).to eq(user)
    end
  end
end
