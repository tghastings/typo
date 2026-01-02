require 'digest/sha1'
module ContentHelper
  # Need to rewrite this one, quick hack to test my changes.
  def page_title
    @page_title
  end

  include SidebarHelper

  def article_links(article, separator="&nbsp;<strong>|</strong>&nbsp;")
    code = []
    code << category_links(article)   unless article.categories.empty?
    code << tag_links(article)        unless article.tags.empty?
    code << comments_link(article)    if article.allow_comments?
    code << trackbacks_link(article)  if article.allow_pings?
    code.join(separator).html_safe
  end

  def category_links(article, prefix="Posted in")
    links = safe_join(article.categories.map { |c| link_to h(c.name), category_url(c), :rel => 'tag' }, ", ")
    safe_join([_(prefix), " ", links])
  end

  def tag_links(article, prefix="Tags")
    links = safe_join(article.tags.map { |tag| link_to tag.display_name, tag.permalink_url, :rel => "tag" }.sort, ", ")
    safe_join([_(prefix), " ", links])
  end

  def next_link(article, prefix="")
    n = article.next
    prefix = (prefix.blank?) ? "#{n.title} &raquo;".html_safe : prefix
    return n ? link_to_permalink(n, prefix) : ''
  end

  def prev_link(article, prefix="")
    p = article.previous
    prefix = (prefix.blank?) ? "&laquo; #{p.title}".html_safe : prefix
    return p ? link_to_permalink(p, prefix) : ''
  end

  def render_to_string(*args, &block)
    controller.send(:render_to_string, *args, &block)
  end
end
