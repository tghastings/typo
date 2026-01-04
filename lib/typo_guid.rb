# frozen_string_literal: true

module TypoGuid
  def create_guid
    begin
      guid
    rescue StandardError
      return true
    end
    return true unless guid.blank?

    self.guid = UUIDTools::UUID.random_create.to_s
  end
end
