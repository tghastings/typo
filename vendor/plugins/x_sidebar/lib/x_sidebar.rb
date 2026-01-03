# coding: utf-8
class XSidebar < Sidebar
  display_name "X (Twitter)"
  description "Display a link to your X (Twitter) profile or custom embed code"

  setting :title, 'X'
  setting :x_username, '', :label => 'X Username (without @)'
  setting :display_name, '', :label => 'Display Name (optional)'
  setting :bio, '', :label => 'Short Bio (optional)'
  setting :custom_embed, '', :label => 'Custom Embed Code (from publish.twitter.com)', :input_type => :text_area

  def profile_url
    return nil if x_username.blank?
    "https://x.com/#{x_username}"
  end

  def show_name
    display_name.present? ? display_name : "@#{x_username}"
  end
end
