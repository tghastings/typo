# frozen_string_literal: true

class EmailNotify
  def self.logger
    @@logger ||= ::Rails.logger || Logger.new($stdout)
  end

  def self.send_comment(comment, user)
    return if user.email.blank?

    begin
      email = NotificationMailer.comment(comment, user)
      EmailNotify.send_message(user, email)
    rescue StandardError => e
      logger.error "Unable to send comment email: #{e.inspect}"
    end
  end

  def self.send_article(article, user)
    return if user.email.blank?

    begin
      email = NotificationMailer.article(article, user)
      EmailNotify.send_message(user, email)
    rescue StandardError => e
      logger.error "Unable to send article email: #{e.inspect}"
    end
  end

  def self.send_message(_user, email)
    email.content_type = 'text/html; charset=utf-8'
    email.deliver_now
  end
end
