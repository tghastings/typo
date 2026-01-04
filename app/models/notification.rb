# frozen_string_literal: true

class Notification < ActiveRecord::Base
  belongs_to :notify_content, optional: true, class_name: 'Content', foreign_key: 'content_id'
  belongs_to :notify_user, optional: true, class_name: 'User', foreign_key: 'user_id'
end
