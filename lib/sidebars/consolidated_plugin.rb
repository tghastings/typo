# frozen_string_literal: true

module Sidebars
  class ConsolidatedPlugin < Sidebars::Plugin
    class << self
      @abstract = true

      def fields
        associated_class.fields
      end

      def default_config
        fields.inject({}) do |acc, item|
          acc.merge(item.key => item.default)
        end
      end

      def description
        associated_class.description
      end
    end

    def index
      @sidebar   = params['sidebar']
      @sb_config = @sidebar.config
      @sidebar.parse_request(params)
      render partial: "sidebars/#{@sidebar.short_name}/content"
    end
  end
end
