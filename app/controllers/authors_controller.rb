# frozen_string_literal: true

class AuthorsController < ContentController
  layout :theme_layout

  def show
    @author = User.find_by_login(params[:id])
    raise ActiveRecord::RecordNotFound unless @author

    @articles = @author.articles.published
    @page_title = this_blog.author_title_template.to_title(@author, this_blog, params)
    @keywords = this_blog.meta_keywords.empty? ? '' : this_blog.meta_keywords
    @description = this_blog.author_desc_template.to_title(@author, this_blog, params)

    # Set auto discovery URLs for feeds
    @auto_discovery_url_rss = "#{this_blog.base_url}/author/#{@author.login}.rss"
    @auto_discovery_url_atom = "#{this_blog.base_url}/author/#{@author.login}.atom"

    respond_to do |format|
      format.html do
        render
      end
      format.rss do
        render_feed 'rss'
      end
      format.atom do
        render_feed 'atom'
      end
    end
  end

  private

  def render_feed(format)
    render "show_#{format}_feed", layout: false
  end
end
