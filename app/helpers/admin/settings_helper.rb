# frozen_string_literal: true

module Admin
  module SettingsHelper
    require 'find'

    def fetch_langs
      options = content_tag(:option, 'Select lang', value: 'en_US')
      Find.find("#{::Rails.root}/lang") do |lang|
        next unless lang =~ /\.rb$/

        lang_pattern = File.basename(lang).gsub('.rb', '')
        options << if this_blog.lang == lang_pattern
                     content_tag(:option, _(lang_pattern.to_s), value: lang_pattern, selected: 'selected')
                   else
                     content_tag(:option, _(lang_pattern.to_s), value: lang_pattern)
                   end
      end
      options
    end

    def show_rss_description
      Article.first.get_rss_description
    rescue StandardError
      ''
    end
  end
end
