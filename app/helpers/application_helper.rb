# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the application.
require 'digest/sha1'

module ApplicationHelper
  # Backward compatibility for form_remote_tag (removed in Rails 4+)
  # Convert old Prototype.js remote forms to modern Rails forms
  def form_remote_tag(options = {}, &)
    html_options = options[:html] || {}
    url = options[:url] || {}

    # Build data attributes for UJS (Unobtrusive JavaScript)
    html_options[:'data-remote'] = true
    html_options[:'data-type'] = 'script'

    form_tag(url, html_options, &)
  end

  # Backward compatibility for submit_to_remote (removed in Rails 4+)
  def submit_to_remote(name, value, options = {})
    options[:html] ||= {}
    options[:html][:'data-remote'] = true
    options[:html][:'data-type'] = 'script'
    options[:html][:type] = 'submit'
    options[:html][:value] = value
    options[:html][:name] = name

    tag(:input, options[:html])
  end

  # Backward compatibility for form_tag_with_upload_progress (removed in Rails 3+)
  def form_tag_with_upload_progress(url_for_options = {}, options = {}, &)
    # Just use regular form_tag - upload progress bars need JavaScript now
    form_tag(url_for_options, options, &)
  end

  # Backward compatibility for link_to_function (removed in Rails 4+)
  # Creates a link that executes JavaScript
  def link_to_function(name, function, html_options = {})
    html_options = html_options.symbolize_keys
    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    href = html_options[:href] || '#'
    html_options.delete(:onclick)
    html_options.delete(:href)
    link_to name, href, html_options.merge(onclick: onclick)
  end

  # Backward compatibility for remote_function (removed in Rails 4+)
  # Generates JavaScript for remote requests using modern Rails UJS
  def remote_function(options)
    url = options[:url]
    url = url_for(url) if url.is_a?(Hash)

    update = options[:update]
    method = options[:method] || :post

    # Build a simple JavaScript that creates a remote request
    # This is a simplified version that works with Rails UJS
    if update
      update.is_a?(Hash) ? update[:success] : update
    end
    "var link = document.createElement('a'); link.href = '#{url}'; link.setAttribute('data-remote', 'true'); link.setAttribute('data-type', 'script'); link.setAttribute('data-method', '#{method}'); Rails.fire(link, 'click');"
  end

  # Backward compatibility for link_to_remote (removed in Rails 4+)
  # Convert old Prototype.js remote links to modern Rails links with data-remote
  def link_to_remote(name, options = {}, html_options = nil)
    html_options ||= options.delete(:html) || {}
    html_options = html_options.symbolize_keys

    url = options[:url]
    url = url_for(url) if url.is_a?(Hash)

    # Add data attributes for UJS
    html_options[:'data-remote'] = true
    html_options[:'data-type'] = 'script'

    # Handle method option
    html_options[:'data-method'] = options[:method] if options[:method]

    # Handle update option (target element to update with response)
    if options[:update]
      update_target = options[:update].is_a?(Hash) ? options[:update][:success] : options[:update]
      html_options[:'data-update'] = update_target
    end

    # Handle confirm option
    html_options[:'data-confirm'] = options[:confirm] if options[:confirm]

    link_to name, url, html_options
  end

  # Legacy CKEditor helper - now deprecated, use markdown editor instead
  # Kept for backward compatibility but returns empty string
  def ckeditor_textarea(_object, _field, _options = {})
    # CKEditor has been removed - use markdown editor via render 'admin/shared/markdown_editor'
    ''
  end

  # Backward compatibility for error_messages_for (removed in Rails 4+)
  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    objects = Array.wrap(options.delete(:object) || params).map do |object|
      object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
      object
    end

    objects.compact!
    count = objects.inject(0) { |sum, object| sum + object.errors.count }

    if count.zero?
      ''
    else
      html = {}
      %i[id class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value if value.present?
        else
          html[key] = 'errorExplanation'
        end
      end

      options[:object_name] ||= params.first

      header_message = "#{pluralize(count, 'error',
                                    'errors')} prohibited this #{options[:object_name].to_s.gsub('_',
                                                                                                 ' ')} from being saved"
      message = 'There were problems with the following fields:'

      error_messages = objects.sum([]) do |object|
        object.errors.full_messages.map do |msg|
          content_tag(:li, msg)
        end
      end.join.html_safe

      contents = +''
      contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
      contents << content_tag(:p, message) unless message.blank?
      contents << content_tag(:ul, error_messages)

      content_tag(:div, contents.html_safe, html)
    end
  end

  # Basic english pluralizer.
  # Axe?

  def pluralize(size, zero, one, many)
    case size
    when 0 then zero
    when 1 then one
    else        format(many, size)
    end
  end

  # Produce a link to the permalink_url of 'item'.
  def link_to_permalink(item, title, anchor = nil, style = nil, nofollow = nil)
    options = {}
    options[:class] = style if style
    options[:rel] = 'nofollow' if nofollow

    link_to title, item.permalink_url(anchor), options
  end

  # The '5 comments' link from the bottom of articles
  def comments_link(article)
    comment_count = article.published_comments.size
    # FIXME: Why using own pluralize metchod when the Localize._ provides the same funciotnality, but better? (by simply calling _('%d comments', comment_count) and using the en translation: l.store "%d comments", ["No nomments", "1 comment", "%d comments"])
    link_to_permalink(article,
                      pluralize(comment_count, _('no comments'), _('1 comment'), _('%d comments', comment_count)), 'comments')
  end

  # wrapper for TypoPlugins::Avatar
  # options is a hash which should contain :email and :url for the plugin
  # (gravatar will use :email, pavatar will use :url, etc.)
  def avatar_tag(options = {})
    # Return empty string if plugin_avatar is not configured
    return '' if this_blog.plugin_avatar.blank?

    # Try to constantize the plugin class, return empty string if it fails
    begin
      avatar_class = this_blog.plugin_avatar.constantize
    rescue NameError
      return ''
    end

    return '' unless avatar_class.respond_to?(:get_avatar)

    avatar_class.get_avatar(options)
  end

  def trackbacks_link(article)
    trackbacks_count = article.published_trackbacks.size
    link_to_permalink(article,
                      pluralize(trackbacks_count, _('no trackbacks'), _('1 trackback'), _('%d trackbacks', trackbacks_count)), 'trackbacks')
  end

  def meta_tag(name, value)
    return if value.blank?

    "<meta name=\"#{CGI.escapeHTML(name.to_s)}\" content=\"#{CGI.escapeHTML(value.to_s)}\">".html_safe
  end

  def date(date)
    "<span class=\"typo_date\">#{date.utc.strftime(_('%%d. %%b', date.utc))}</span>"
  end

  def toggle_effect(domid, true_effect, true_opts, false_effect, false_opts)
    "$('#{domid}').style.display == 'none' ? new #{false_effect}('#{domid}', {#{false_opts}}) : new #{true_effect}('#{domid}', {#{true_opts}}); return false;"
  end

  def markup_help_popup(markup, text)
    if markup && (markup.commenthelp.size > 1)
      "<a href=\"#{url_for controller: 'articles', action: 'markup_help',
                           id: markup.id}\" onclick=\"return popup(this, 'Typo Markup Help')\">#{text}</a>"
    else
      ''
    end
  end

  def admin_tools_for(model)
    type = model.class.to_s.downcase
    tag = []
    tag << content_tag('div',
                       link_to('nuke', {
                                 controller: 'admin/feedback',
                                 action: 'delete',
                                 id: model.id
                               },
                               remote: true,
                               method: :post,
                               data: { type: 'script', confirm: _('Are you sure you want to delete this %s?', type.to_s) },
                               class: 'admintools') <<
                       link_to('edit', {
                                 controller: 'admin/feedback',
                                 action: 'edit', id: model.id
                               }, class: 'admintools'),
                       id: "admin_#{type}_#{model.id}", style: 'display: none')
    tag.join(' | ')
  end

  def onhover_show_admin_tools(type, id = nil)
    tag = []
    tag << %{ onmouseover="if (getCookie('typo_user_profile') == 'admin') { Element.show('admin_#{[type,
                                                                                                   id].compact.join('_')}'); }" }
    tag << %{ onmouseout="Element.hide('admin_#{[type, id].compact.join('_')}');" }
    tag
  end

  def render_flash
    output = []

    flash&.each do |key, value|
      output << "<span class=\"#{key.to_s.downcase}\">#{h(value)}</span>"
    end

    output.join("<br>\n")
  end

  def feed_title
    if @feed_title
      @feed_title
    elsif @page_title && !@page_title.blank?
      "#{this_blog.blog_name} : #{@page_title}"
    else
      this_blog.blog_name
    end
  end

  def html(content, what = :all, _deprecated = false)
    content.html(what)
  end

  def author_link(article)
    if this_blog.link_to_author && article.user && article.user.email.to_s.size.positive?
      "<a href=\"mailto:#{h article.user.email}\">#{h article.user.name}</a>"
    elsif article.user && article.user.name.to_s.size.positive?
      h article.user.name
    else
      h article.author
    end
  end

  def google_analytics
    return if this_blog.google_analytics.empty?

    <<-HTML
      <script>
      var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
      document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js'%3E%3C/script%3E"));
      </script>
      <script>
      var pageTracker = _gat._getTracker("#{this_blog.google_analytics}");
      pageTracker._trackPageview();
      </script>
    HTML
  end

  def javascript_include_lang
    javascript_include_tag "lang/#{Localization.lang}" if File.exist? File.join(::Rails.root.to_s, 'public',
                                                                                'lang', Localization.lang.to_s)
  end

  def use_canonical
    "<link rel='canonical' href='#{@canonical_url}'>".html_safe unless @canonical_url.nil?
  end

  def page_header
    # Collect whiteboard includes from content
    page_header_includes = content_array.collect(&:whiteboard).collect do |w|
      w.select { |k, _v| k =~ /^page_header_/ }.collect do |(_k, v)|
        v.to_s.strip
      end
    end.flatten.uniq.reject(&:blank?)

    # Build output - middleware will beautify it
    lines = []

    # Meta tags
    lines << meta_tag('ICBM', this_blog.geourl_location) unless this_blog.geourl_location.blank?
    lines << meta_tag('description', @description) unless @description.blank?
    lines << meta_tag('robots', 'noindex, follow') unless @noindex.nil?
    unless this_blog.google_verification.blank?
      lines << meta_tag('google-site-verification',
                        this_blog.google_verification)
    end
    lines << "<meta name=\"generator\" content=\"Typo #{TYPO_VERSION}\">"
    lines << show_meta_keyword

    # Links
    lines << '<link rel="EditURI" type="application/rsd+xml" title="RSD" href="/xml/rsd">'
    lines << "<link rel=\"alternate\" type=\"application/atom+xml\" title=\"Atom\" href=\"#{feed_atom}\">"
    lines << "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"#{feed_rss}\">"

    # JavaScript
    lines << javascript_importmap_tags.to_s.strip
    lines << javascript_include_tag('cookies', 'typo').to_s.strip

    # Stylesheets
    lines << stylesheet_link_tag('coderay', 'user-styles').to_s.strip

    # Optional includes
    lines << javascript_include_lang
    lines << javascript_tag("window._token = '#{form_authenticity_token}'").to_s.strip

    # Plugin includes
    page_header_includes.each { |inc| lines << inc }

    # Canonical URL
    lines << use_canonical if this_blog.use_canonical_url

    # Custom tracking
    lines << this_blog.custom_tracking_field.to_s.strip unless this_blog.custom_tracking_field.blank?

    # Google Analytics
    lines << google_analytics

    # Join and return, removing trailing slashes from void elements
    output = lines.compact.reject { |l| l.to_s.strip.empty? }.join("\n")
    output.gsub(%r{ />}, '>').html_safe
  end

  def feed_atom
    if params[:action] == 'search'
      "#{this_blog.base_url}/search/#{params[:q]}.atom"
    elsif !@article.nil?
      @article.feed_url(:atom)
    elsif !@auto_discovery_url_atom.nil?
      @auto_discovery_url_atom
    else
      "#{this_blog.base_url}/articles.atom"
    end
  end

  def feed_rss
    if params[:action] == 'search'
      "#{this_blog.base_url}/search/#{params[:q]}.rss"
    elsif !@article.nil?
      @article.feed_url(:rss20)
    elsif !@auto_discovery_url_rss.nil?
      @auto_discovery_url_rss
    else
      "#{this_blog.base_url}/articles.rss"
    end
  end

  def render_the_flash
    return unless flash[:notice] || flash[:error] || flash[:warning]

    the_class = flash[:error] ? 'error' : 'success'

    html = "<div class='alert-message #{the_class}'>"
    html << "<a class='close' href='#'>×</a>"
    begin
      html << render_flash
    rescue StandardError
      nil
    end
    html << '</div>'
    html.html_safe
  end

  def content_array
    if @articles
      @articles
    elsif @article
      [@article]
    elsif @page
      [@page]
    else
      []
    end
  end

  def new_js_distance_of_time_in_words_to_now(date)
    time = _(date.utc.strftime(_('%%a, %%d %%b %%Y %%H:%%M:%%S GMT', date.utc)))
    timestamp = date.utc.to_i
    "<span class=\"typo_date date gmttimestamp-#{timestamp}\" title=\"#{time}\" >#{time}</span>"
  end

  def display_date(date)
    date.strftime(this_blog.date_format)
  end

  def display_time(time)
    time.strftime(this_blog.time_format)
  end

  def display_date_and_time(timestamp)
    return new_js_distance_of_time_in_words_to_now(timestamp) if this_blog.date_format == 'distance_of_time_in_words'

    "#{display_date(timestamp)} #{_('at')} #{display_time(timestamp)}"
  end

  def js_distance_of_time_in_words_to_now(date)
    display_date_and_time date
  end

  def show_meta_keyword
    return unless this_blog.use_meta_keyword

    meta_tag 'keywords', @keywords unless @keywords.blank?
  end

  def show_menu_for_post_type(posttype, before = '<li>', after = '</li>')
    list = Article.where('post_type = ?', posttype)
    return if list.empty?

    html = +''
    list.each do |item|
      html << before
      html << link_to_permalink(item, item.title)
      html << after
    end

    html
  end

  def this_blog
    @this_blog ||= Blog.default
  end

  def will_paginate(items, params = {})
    paginate(items, params)
  end
end
