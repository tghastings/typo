# frozen_string_literal: true

feed.title(feed_title)
feed.subtitle(this_blog.blog_subtitle, 'type' => 'html') unless this_blog.blog_subtitle.blank?
feed.updated items.first.updated_at if items.first
feed.generator 'Typo', uri: 'http://www.typosphere.org', version: TYPO_VERSION
