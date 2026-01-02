class XmlSidebar < Sidebar
  display_name "XML Syndication"
  description "RSS and Atom feeds"

  setting :articles,   true,  :input_type => :checkbox
  setting :comments,   true,  :input_type => :checkbox
  setting :trackbacks, false, :input_type => :checkbox
  setting :article_comments, true, :input_type => :checkbox
  setting :category_feeds, false, :input_type => :checkbox
  setting :tag_feeds, false, :input_type => :checkbox

  setting :format, 'atom', :input_type => :radio,
          :choices => [["rss",  "RSS"], ["atom", "Atom"]]

  def format_strip
    strip_format = self.format || 'atom'
    strip_format.gsub(/[\d.]+/, '')
  end

end
