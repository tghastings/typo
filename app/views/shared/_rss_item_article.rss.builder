# frozen_string_literal: true

xm.item do
  xm.title item.title
  content_html =
    if item.password_protected?
      "<p>This article is password protected. Please <a href='#{item.permalink_url}'>fill in your password</a> to read it</p>"
    elsif this_blog.hide_extended_on_rss
      html(item, :body)
    else
      html(item, :all)
    end
  xm.description content_html + item.get_rss_description
  xm.pubDate pub_date(item.published_at)
  xm.guid "urn:uuid:#{item.guid}", 'isPermaLink' => 'false'
  xm.author "#{item.user.email} (#{item.user.name})" if item.link_to_author?
  xm.comments(item.permalink_url('comments'))
  item.categories.each do |category|
    xm.category category.name
  end
  item.tags.each do |tag|
    xm.category tag.display_name
  end

  # RSS 2.0 only allows a single enclosure per item, so only include the first one here.
  unless item.resources.empty?
    resource = item.resources.first
    xm.enclosure(
      url: item.blog.file_url(resource.filename),
      length: resource.size,
      type: resource.mime
    )
  end
  xm.trackback :ping, item.trackback_url if item.allow_pings?
  xm.link item.permalink_url
end
