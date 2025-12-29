# Rails 7 compatibility: Restore InstanceTag for calendar_date_select
module ActionView
  module Helpers
    class InstanceTag
      def self.new_with_backwards_compatibility(object_name, method_name, template_object, object = nil)
        new(object_name, method_name, template_object, object)
      end

      def initialize(object_name, method_name, template_object, object = nil)
        @object_name = object_name
        @method_name = method_name
        @template_object = template_object
        @object = object || template_object.instance_variable_get("@#{object_name}")
      end

      def to_input_field_tag(field_type, options = {})
        field_type = field_type.to_s
        options[:value] ||= value_before_type_cast
        options[:id] ||= "#{@object_name}_#{@method_name}"
        options[:name] ||= "#{@object_name}[#{@method_name}]"

        case field_type
        when 'hidden'
          @template_object.hidden_field_tag(options[:name], options[:value], options.except(:name, :value))
        when 'text'
          @template_object.text_field_tag(options[:name], options[:value], options.except(:name, :value))
        else
          @template_object.text_field_tag(options[:name], options[:value], options.except(:name, :value))
        end
      end

      def value_before_type_cast
        return @object.send(@method_name) if @object && @object.respond_to?(@method_name)
        return @object.send("#{@method_name}_before_type_cast") if @object && @object.respond_to?("#{@method_name}_before_type_cast")
        nil
      end
    end
  end
end

# Rails 7 compatibility: Restore options_for_javascript helper
module ActionView
  module Helpers
    module JavaScriptHelper
      # Converts a Ruby hash to a JavaScript options string
      def options_for_javascript(options)
        return '{}' if options.blank?

        pairs = options.map do |key, value|
          "#{key}: #{javascript_object_for(value)}"
        end
        "{#{pairs.join(', ')}}"
      end

      def javascript_object_for(value)
        case value
        when String
          # Don't quote if it's already a function or if it starts with specific patterns
          if value =~ /^function/ || value =~ /^new Date/ || value =~ /^\[/ || value == 'this'
            value
          else
            "'#{escape_javascript(value)}'"
          end
        when Symbol
          "'#{value}'"
        when Numeric, TrueClass, FalseClass
          value.to_s
        when NilClass
          'null'
        when Array
          "[#{value.map { |v| javascript_object_for(v) }.join(', ')}]"
        when Hash
          options_for_javascript(value)
        else
          "'#{escape_javascript(value.to_s)}'"
        end
      end

      # Converts an array or string to JavaScript format
      def array_or_string_for_javascript(option)
        if option.is_a?(Array)
          "[#{option.map { |v| "'#{escape_javascript(v.to_s)}'" }.join(', ')}]"
        elsif option.is_a?(String)
          "'#{escape_javascript(option)}'"
        else
          option.to_s
        end
      end
    end
  end
end

# Rails 7 compatibility: Restore Prototype.js helpers
module ActionView
  module Helpers
    module PrototypeHelper
      # link_to_function creates a link that calls JavaScript
      def link_to_function(name, function, html_options = {})
        onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
        href = html_options[:href] || '#'

        content_tag(:a, name, html_options.merge(onclick: onclick, href: href))
      end

      # update_page is for RJS-style page updates
      def update_page(&block)
        page = JavaScriptGenerator.new(self, &block)
        javascript_tag(page.to_s)
      end

      def update_page_tag(&block)
        update_page(&block)
      end

      class JavaScriptGenerator
        def initialize(context, &block)
          @context = context
          @lines = []
          instance_eval(&block) if block_given?
        end

        def to_s
          @lines.join("\n")
        end

        def <<(line)
          @lines << line
        end

        def [](id)
          JavaScriptElementProxy.new(self, id)
        end

        def method_missing(method, *args)
          @lines << "#{method}(#{args_for_javascript(args)});"
          self
        end

        private

        def args_for_javascript(args)
          args.map { |arg|
            case arg
            when String then "'#{arg.gsub("'", "\\\\'")}'"
            when Hash then @context.options_for_javascript(arg)
            else arg.to_s
            end
          }.join(', ')
        end
      end

      class JavaScriptElementProxy
        def initialize(generator, id)
          @generator = generator
          @id = id
        end

        def method_missing(method, *args)
          @generator << "$(#{@id.to_json}).#{method}(#{args_for_javascript(args)});"
          self
        end

        def replace_html(value)
          @generator << "$(#{@id.to_json}).innerHTML = #{value.to_json};"
          self
        end

        def replace(value)
          @generator << "Element.replace(#{@id.to_json}, #{value.to_json});"
          self
        end

        def remove
          @generator << "Element.remove(#{@id.to_json});"
          self
        end

        private

        def args_for_javascript(args)
          args.map { |arg|
            case arg
            when String then arg.to_json
            when Hash then @generator.instance_variable_get(:@context).options_for_javascript(arg)
            else arg.to_s
            end
          }.join(', ')
        end
      end
    end
  end
end

# Include calendar_date_select helpers
Rails.application.config.after_initialize do
  ActionView::Base.include CalendarDateSelect::FormHelpers
  ActionView::Base.include CalendarDateSelect::IncludesHelper
end
