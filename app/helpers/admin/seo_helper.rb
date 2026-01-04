# frozen_string_literal: true

module Admin
  module SeoHelper
    def robot_writable?
      File.writable? "#{::Rails.root}/public/robots.txt"
    end
  end
end
