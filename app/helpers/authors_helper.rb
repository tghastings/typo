# frozen_string_literal: true

module AuthorsHelper
  def display_profile_item(item, show_item, item_desc)
    return unless show_item

    item = link_to(item, item) if is_url?(item)
    content_tag :li do
      "#{item_desc} #{item}"
    end
  end

  def is_url?(str)
    [URI::HTTP, URI::HTTPS].include?(URI.parse(str.to_s).class)
  rescue URI::InvalidURIError
    false
  end
end
