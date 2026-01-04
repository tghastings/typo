# frozen_string_literal: true

module Admin
  class TextfiltersController < Admin::BaseController
    def macro_help
      @macro = TextFilter.available_filters.find { |filter| filter.short_name == params[:id] }
      render html: BlueCloth.new(@macro.help_text).to_html.html_safe
    end
  end
end
