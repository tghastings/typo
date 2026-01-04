# frozen_string_literal: true

module Admin
  module RedirectsHelper
    def show_redirect_actions(item)
      <<-HTML
      <div class='action'>
        <small>#{link_to _('Edit'), action: 'edit', id: item.id}</small> |
        <small>#{link_to _('Delete'), action: 'destroy', id: item.id}</small>
    </div>
      HTML
    end
  end
end
