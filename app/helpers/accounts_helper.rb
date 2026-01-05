# frozen_string_literal: true

module AccountsHelper
  def display_accounts_link
    html = +''
    if this_blog.allow_signup == 1
      html << link_to("<small>#{_('Create an account')}</small>".html_safe,
                      action: 'signup')
    end
    html << link_to("<small> • #{_("I've lost my password")}</small>".html_safe, action: 'recover_password')
    html.html_safe
  end
end
