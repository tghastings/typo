module Admin::BaseHelper
  include ActionView::Helpers::DateHelper

  # Stub for deprecated Prototype helper - draggable_element
  # Returns an empty string since the Prototype library is no longer used
  def draggable_element(element_id, options = {})
    # Deprecated Prototype helper - functionality handled by modern JS
    ''
  end

  # Stub for deprecated Prototype helper - sortable_element
  # Returns an empty string since the Prototype library is no longer used
  def sortable_element(element_id, options = {})
    # Deprecated Prototype helper - functionality handled by modern JS
    ''
  end

  # Convert menu URL hash to path string for Rails 7 compatibility
  def menu_url_to_path(url)
    return url unless url.is_a?(Hash)
    controller = url[:controller].to_s.sub(/^\//, '').sub(/^admin\//, '')
    path = "/admin/#{controller}"
    path += "/#{url[:action]}" if url[:action] && url[:action].to_s != 'index'
    path += "/#{url[:id]}" if url[:id]
    path
  end

  def subtabs_for(current_module)
    output = []
    AccessControl.project_module(current_user.profile_label, current_module).submenus.each_with_index do |m,i|
      next if m.name.empty?
      current =
      output << subtab(_(m.name), (m.url[:controller] == params[:controller] && m.url[:action] == params[:action]) ? '' : m.url)
    end
    output.join("\n").html_safe
  end

  def subtab(label, options = {})
    return content_tag :li, "<span class='subtabs'>#{label}</span>".html_safe if options.empty?
    content_tag :li, link_to(label, menu_url_to_path(options))
  end

  def show_page_heading
    return if @page_heading.nil? or @page_heading.blank?
    heading = "<div class='page-header'>"
    heading << content_tag(:h2, @page_heading.html_safe)
    heading << "</div>"
    heading.html_safe
  end

  def cancel(url = {:action => 'index'})
    # Convert hash to path for Rails 7 compatibility
    if url.is_a?(Hash) && url[:action]
      ctrl = controller.controller_name rescue 'content'
      url = url[:action] == 'index' ? "/admin/#{ctrl}" : "/admin/#{ctrl}/#{url[:action]}"
    end
    link_to _("Cancel"), url, :class => 'btn'
  end

  def save(val = _("Store"))
    ('<input type="submit" value="' + val + '" class="btn primary" />').html_safe
  end

  def link_to_edit(label, record, ctrl = nil)
    ctrl ||= controller.controller_name rescue 'content'
    link_to label, "/admin/#{ctrl}/edit/#{record.id}", :class => 'edit'
  end

  def link_to_edit_with_profiles(label, record, ctrl = nil)
    if current_user.admin? || current_user.id == record.user_id
      ctrl ||= controller.controller_name rescue 'content'
      link_to label, "/admin/#{ctrl}/edit/#{record.id}", :class => 'edit'
    end
  end

  def link_to_destroy(record, ctrl = nil)
    ctrl ||= controller.controller_name rescue 'content'
    link_to image_tag('admin/delete.png', :alt => _("delete"), :title => _("Delete content")),
      "/admin/#{ctrl}/destroy/#{record.id}"
  end

  def link_to_destroy_with_profiles(record, ctrl = nil)
    if current_user.admin? || current_user.id == record.user_id
      ctrl ||= controller.controller_name rescue 'content'
      link_to(_("delete"),
        "/admin/#{ctrl}/destroy/#{record.id}", data: { confirm: _("Are you sure?") }, method: :post, :class => 'btn danger', :title => _("Delete content"))
      end
  end

  def text_filter_options
    TextFilter.all.collect do |filter|
      [ filter.description, filter ]
    end
  end

  def text_filter_options_with_id
    TextFilter.all.collect do |filter|
      [ filter.description, filter.id ]
    end
  end

  def plugin_options(kind, blank = true)
    plugins = TypoPlugins::Keeper.available_plugins(kind) || []
    r = plugins.collect do |plugin|
      [ plugin.name, plugin.to_s ]
    end
    blank ? r << [_("none"),''] : r
  end

  def alternate_class
    @class = @class != '' ? '' : 'class="shade"'
  end

  def task_overview
    ctrl = controller.controller_name rescue 'content'
    index_path = "/admin/#{ctrl}"
    content_tag :li, link_to(_('Back to list'), index_path)
  end

  def class_tab
    ''
  end

  def class_selected_tab
    'active'
  end

  def class_articles
    if controller.controller_name  =~ /content|tags|categories|feedback|post_type/
      return class_selected_tab if controller.action_name =~ /list|index|show|article|destroy|new|edit/
    end
    class_tab
  end

  def class_media
    if controller.controller_name  =~ /resources/
      return class_selected_tab
    end
    class_tab
  end

  def class_pages
    if controller.controller_name  =~ /pages/
      return class_selected_tab if controller.action_name =~ /index|destroy|new|edit/
    end
    class_tab
  end

  def class_themes
    return class_selected_tab if controller.controller_name  =~ /themes|sidebar/
    class_tab
  end

  def class_dashboard
    return class_selected_tab if controller.controller_name  =~ /dashboard/
    class_tab
  end

  def class_settings
    return class_selected_tab if controller.controller_name  =~ /settings|users|cache|redirects/
    class_tab
  end

  def class_profile
    return class_selected_tab if controller.controller_name  =~ /profiles/
    class_tab
  end

  def class_seo
    return class_selected_tab if controller.controller_name  =~ /seo/
    class_tab
  end

  def collection_select_with_current(object, method, collection, value_method, text_method, current_value, prompt=false)
    result = "<select name='#{object}[#{method}]'>\n"

    if prompt == true
      result << "<option value=''>" << _("Please select") << "</option>"
    end
    for element in collection
      if current_value and current_value == element.send(value_method)
        result << "<option value='#{element.send(value_method)}' selected='selected'>#{element.send(text_method)}</option>\n"
      else
        result << "<option value='#{element.send(value_method)}'>#{element.send(text_method)}</option>\n"
      end
    end
    result << "</select>\n"
    result.html_safe
  end

  def render_void_table(size, cols)
    if size == 0
      ("<tr>\n<td colspan=#{cols}>" + _("There are no %s yet. Why don't you start and create one?", _(controller.controller_name)) + "</td>\n</tr>\n").html_safe
    end
  end

  def cancel_or_save(message=_("Save"))
    result = cancel.to_s
    result << " "
    result << _("or")
    result << " "
    result << save(message)
    result.html_safe
  end

    def get_short_url(item)
      return "" if item.short_url.nil?
      sprintf("<small>%s %s</small>", _("Short url:"), link_to(item.short_url, item.short_url)).html_safe
    end

  def show_actions item
    ctrl = controller.controller_name rescue 'content'
    html = <<-HTML
      <div class='action'>
        <small>#{link_to_published item}</small> |
        <small>#{link_to _("Edit"), "/admin/#{ctrl}/edit/#{item.id}"}</small> |
        <small>#{link_to _("Delete"), "/admin/#{ctrl}/destroy/#{item.id}", data: { confirm: _("Are you sure?") }, method: :post}</small> |
        #{get_short_url item}
    </div>
    HTML
    html.html_safe
  end

  def format_date(date)
    date.strftime('%d/%m/%Y')
  end

  def format_date_time(date)
    date.strftime('%d/%m/%Y %H:%M')
  end

  def link_to_published(item)
    return link_to_permalink(item,  _("Show"), nil, 'published') if item.published
    link_to(_("Preview"), "/articles/preview/#{item.id}", {:class => 'unpublished', :target => '_new'})
  end

  def published_or_not(item)
    return "<span class='label success'>#{_("Published")}</span>".html_safe if item.state.to_s.downcase == 'published'
    return "<span class='label notice'>#{_("Draft")}</span>".html_safe if item.state.to_s.downcase == 'draft'
    return "<span class='label important'>#{_("Withdrawn")}</span>".html_safe if item.state.to_s.downcase == 'withdrawn'
    return "<span class='label warning'>#{_("Publication pending")}</span>".html_safe if item.state.to_s.downcase == 'publicationpending'
  end

  def macro_help_popup(macro, text)
    # Always show the link - the macro table is only visible in HTML mode anyway
    "<a href=\"/admin/textfilters/macro_help/#{macro.short_name}\" onclick=\"return popup(this, 'Typo Macro Help')\">#{text}</a>".html_safe
  end

  def render_macros(macros)
    macros ||= []
    result = "".html_safe
    result << link_to(_("Show help on Typo macros") + " (+/-)", "#", onclick: "Element.toggle('macros'); return false;")
    result << "<table id='macros' style='display: none;'>".html_safe
    result << "<tr><th>#{_('Name')}</th><th>#{_('Description')}</th><th>#{_('Tag')}</th></tr>".html_safe

    # Filter out the meta-expanders, only show actual user-facing macros
    user_macros = macros.reject { |f| f.short_name =~ /macropost|macropre/ }
    for macro in user_macros.sort_by { |f| f.short_name }
      result << "<tr>".html_safe
      result << "<td>#{macro_help_popup macro, macro.display_name}</td>".html_safe
      result << "<td>#{h macro.description}</td>".html_safe
      result << "<td><code>&lt;typo:#{h macro.short_name}&gt;</code></td>".html_safe
      result << "</tr>".html_safe
    end
    result << "</table>".html_safe
    result
  end

  def build_editor_link(label, action, id, update, editor)
    link = link_to(label, "#",
      class: 'ui-button-text',
      onclick: "switchEditor('#{editor}'); return false;"
    )
    link << image_tag("spinner-blue.gif", :id => "update_spinner_#{id}", :style => 'display:none;')
    link.html_safe
  end

  def display_pagination(collection, cols, first='', last='')
    "<tr><td class='#{first} #{last}' colspan=#{cols} class='paginate'>#{paginate(collection)}</td></tr>".html_safe
  end

  def show_thumbnail_for_editor(image)
    # Use Active Storage for file URLs
    if image.file.attached?
      file_url = rails_blob_path(image.file, only_path: true)

      # Use variant for thumbnail if image is variable
      if image.file.variable?
        thumbnail_url = rails_representation_path(image.file.variant(resize_to_limit: [100, 100]), only_path: true)
      else
        thumbnail_url = file_url
      end
    else
      # Fallback for legacy files without attachments
      file_url = "#{this_blog.base_url}/files/#{image.filename}"
      thumbnail_url = "#{this_blog.base_url}/images/thumb_blank.jpg"
    end

    picture = "<a onclick=\"edInsertImageFromCarousel('article_body_and_extended', '#{file_url}');\" />"
    picture << "<img class='tumb' src='#{thumbnail_url}' "
    picture << "alt='#{image.filename}' />"
    picture << "</a>"
    picture.html_safe
  end

  def save_settings
    "<div class='actions'>#{cancel} #{_("or")} #{save(_("Update settings"))}</div>".html_safe
  end
end
