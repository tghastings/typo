# frozen_string_literal: true

class Sidebar < ActiveRecord::Base
  serialize :config, coder: YAML

  # Handle STI subclass lookup errors gracefully for invalid sidebar types
  class << self
    def find_sti_class(type_name)
      super
    rescue NameError
      # Return Sidebar as fallback for unknown types, but mark for filtering
      Sidebar
    end

    # Override sti_class_for to handle unknown types
    def sti_class_for(type_name)
      if type_name.present?
        begin
          type_name.constantize
        rescue NameError
          # Skip unknown sidebar types by returning nil indicator
          nil
        end
      else
        self
      end
    end
  end

  # Mark records with invalid type for filtering
  def valid_sidebar_type?
    self.class != Sidebar || type.blank?
  end

  class Field
    attr_accessor :key, :options, :default

    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::FormOptionsHelper

    def initialize(key, default, options = {})
      @key = key.to_s
      @default = default
      @options = options
    end

    def label
      options[:label] || key.humanize.gsub(/url/i, 'URL')
    end

    def label_html(_sidebar)
      content_tag('label', label)
    end

    def input_html(sidebar)
      text_field_tag(input_name(sidebar), sidebar.config[key], { class: 'span4' })
    end

    def line_html(sidebar)
      html = label_html(sidebar)
      html << content_tag(:div, input_html(sidebar), class: 'input')
      html.html_safe
    end

    def input_name(sidebar)
      "configure[#{sidebar.id}][#{key}]"
    end

    def canonicalize(value)
      value
    end

    class SelectField < self
      def input_html(sidebar)
        select_tag(input_name(sidebar),
                   options_for_select(options[:choices], sidebar.config[key]),
                   options)
      end
    end

    class TextAreaField < self
      def input_html(sidebar)
        html_options = { 'rows' => '10', 'class' => 'span4' }.update(options.stringify_keys)
        text_area_tag(input_name(sidebar), sidebar.config[key], html_options)
      end
    end

    class RadioField < self
      def input_html(sidebar)
        options[:choices].collect do |choice|
          value = value_for(choice)
          radio_button_tag(input_name(sidebar), value,
                           value == sidebar.config[key], options) +
            content_tag('label', label_for(choice))
        end.join('<br />').html_safe
      end

      def label_for(choice)
        choice.is_a?(Array) ? choice.last : choice.to_s.humanize
      end

      def value_for(choice)
        choice.is_a?(Array) ? choice.first : choice
      end
    end

    class CheckBoxField < self
      def input_html(sidebar)
        hidden_field_tag(input_name(sidebar), 0) +
          check_box_tag(input_name(sidebar), 1, sidebar.config[key], options)
      end

      def line_html(sidebar)
        input_html(sidebar) + ' '.html_safe + label_html(sidebar) + tag(:br)
      end

      def canonicalize(value)
        case value
        when '0'
          false
        else
          true
        end
      end
    end

    def self.build(key, default, options)
      class_for(options).new(key, default, options)
    end

    def self.class_for(options)
      case options[:input_type]
      when :text_area
        TextAreaField
      when :textarea
        TextAreaField
      when :radio
        RadioField
      when :checkbox
        CheckBoxField
      when :select
        SelectField
      else
        if options[:choices]
          SelectField
        else
          self
        end
      end
    end
  end

  class << self
    attr_accessor :view_root

    def find_all_visible
      where('active_position is not null').order('active_position').to_a
    end

    def find_all_staged
      where('staged_position is not null').order('staged_position').to_a
    end

    def purge
      where('active_position is null and staged_position is null').delete_all
    end

    def setting(key, default = nil, options = {})
      return if method_defined?(key.to_s)

      fields << Field.build(key.to_s, default, options)
      fieldmap.update(key.to_s => fields.last)
      send(:define_method, key) do
        config[key.to_s]
      end
      send(:define_method, "#{key}=") do |newval|
        config[key.to_s] = newval
      end
    end

    def fieldmap
      @fieldmap ||= {}
    end

    def fields
      @fields ||= []
    end

    attr_writer :fields

    def description(desc = nil)
      if desc
        @description = desc
      else
        @description
      end
    end

    def lifetime(timeout = nil)
      if timeout
        @lifetime = timeout
      else
        @lifetime
      end
    end

    def short_name
      to_s.underscore.split('_').first
    end

    def path_name
      to_s.underscore
    end

    def display_name(new_dn = nil)
      @display_name = new_dn if new_dn
      @display_name || short_name.humanize
    end

    def available_sidebars
      Sidebar.descendants.sort_by(&:to_s)
    end
  end

  def blog
    Blog.default
  end

  def initialize(*args, &)
    # Handle ActionController::Parameters for Rails 7 compatibility
    args[0] = args.first.to_unsafe_h if args.first.is_a?(ActionController::Parameters)
    if block_given?
      super
    else
      super(*args)
    end
    self.class.fields.each do |field|
      config[field.key] = field.default unless config.key?(field.key)
    end
  end

  def publish
    self.active_position = staged_position
  end

  def config
    self[:config] ||= {}
  end

  def sidebar_controller
    @sidebar_controller ||= SidebarController.available_sidebars.find { |s| s.short_name == controller }
  end

  def html_id
    "#{short_name}-#{id}"
  end

  def parse_request(contents, params); end

  def fields
    self.class.fields
  end

  def fieldmap(field = nil)
    if field
      self.class.fieldmap[field.to_s]
    else
      self.class.fieldmap
    end
  end

  def description
    self.class.description
  end

  def short_name
    self.class.short_name
  end

  def display_name
    self.class.display_name
  end

  def content_partial
    "/#{self.class.path_name}/content"
  end

  def to_locals_hash
    fields.inject({ sidebar: self }) do |hash, field|
      hash.merge(field.key => config[field.key])
    end
  end

  def lifetime
    self.class.lifetime
  end

  def view_root
    self.class.view_root
  end
end
