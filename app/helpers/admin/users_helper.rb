# frozen_string_literal: true

module Admin
  module UsersHelper
    def get_select(needle, haystack)
      'selected="selected"' if needle.to_s == haystack.to_s
    end

    def render_options_for_display_name
      options = []
      options << content_tag(:option, @user.login, value: @user.login, selected: @user.name == @user.login)

      options << content_tag(:option, @user.nickname, value: @user.nickname, selected: @user.name == @user.nickname) if @user.nickname.present?

      if @user.firstname.present?
        options << content_tag(:option, @user.firstname, value: @user.firstname,
                                                         selected: @user.name == @user.firstname)
      end

      options << content_tag(:option, @user.lastname, value: @user.lastname, selected: @user.name == @user.lastname) if @user.lastname.present?

      if @user.firstname.present? && @user.lastname.present?
        full_name = "#{@user.firstname} #{@user.lastname}"
        options << content_tag(:option, full_name, value: full_name, selected: @user.name == full_name)
      end

      safe_join(options)
    end
  end
end
