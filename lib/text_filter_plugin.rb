# frozen_string_literal: true

class TextFilterPlugin
  class << self
    include TypoPlugins
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper
  end

  @@filter_map = {}
  def self.inherited(sub)
    super
    return unless sub.to_s =~ /^Plugin/ || sub.to_s =~ /^Typo::Textfilter/

    name = sub.short_name
    @@filter_map[name] = sub
  end

  def self.filter_map
    @@filter_map
  end

  plugin_display_name 'Unknown Text Filter'
  plugin_description 'Unknown Text Filter Description'

  def self.reloadable?
    false
  end

  # The name that needs to be used when refering to the plugin's
  # controller in render statements
  def self.component_name
    raise "I don't know who I am: #{self}" unless to_s =~ /::([a-zA-Z]+)$/

    "plugins/textfilters/#{::Regexp.last_match(1)}".downcase
  end

  # The name that's stored in the DB.  This is the final chunk of the
  # controller name, like 'markdown' or 'smartypants'.
  def self.short_name
    component_name.split(%r{/}).last
  end

  def self.default_config
    {}
  end

  def self.help_text
    ''
  end

  def self.sanitize(*)
    (@sanitizer ||= Rails::HTML4::SafeListSanitizer.new).sanitize(*)
  end

  def self.default_helper_module!; end

  # Look up a config paramater, falling back to the default as needed.
  def self.config_value(params, name)
    params[:filterparams][name] || default_config[name][:default]
  end

  def self.logger
    @logger ||= ::Rails.logger || Logger.new($stdout)
  end
end

class TextFilterPlugin::PostProcess < TextFilterPlugin
end

class TextFilterPlugin::Macro < TextFilterPlugin
  # Utility function -- hand it a XML string like <a href="foo" title="bar">
  # and it'll give you back { "href" => "foo", "title" => "bar" }
  def self.attributes_parse(string)
    attributes = {}

    string.gsub(/([^ =]+="[^"]*")/) do |match|
      key, value = match.split('=', 2)
      attributes[key] = value.gsub('"', '')
    end

    string.gsub(/([^ =]+='[^']*')/) do |match|
      key, value = match.split('=', 2)
      attributes[key] = value.gsub('\'', '')
    end

    attributes
  end

  def self.filtertext(blog, content, text, params)
    params[:filterparams]
    regex1 = %r{<typo:#{short_name}(?:[ \t][^>]*)?/>}
    regex2 = %r{<typo:#{short_name}([ \t][^>]*)?>(.*?)</typo:#{short_name}>}m

    new_text = text.gsub(regex1) do |match|
      macrofilter(blog, content, attributes_parse(match), params)
    end

    new_text.gsub(regex2) do |_match|
      macrofilter(blog, content, attributes_parse(::Regexp.last_match(1).to_s), params, ::Regexp.last_match(2).to_s)
    end
  end
end

class TextFilterPlugin::MacroPre < TextFilterPlugin::Macro
end

class TextFilterPlugin::MacroPost < TextFilterPlugin::Macro
end

class TextFilterPlugin::Markup < TextFilterPlugin
end

# Only define these classes if they haven't been defined yet (Rails 8 autoloading fix)
unless defined?(Typo::Textfilter::MacroPostExpander)
  class Typo
    class Textfilter
      class MacroPostExpander < TextFilterPlugin::MacroPost
        plugin_display_name 'MacroPost'
        plugin_description 'Macro expansion meta-filter (post-markup)'

        def self.short_name
          'macropost'
        end

        def self.filtertext(blog, content, text, params)
          params[:filterparams]

          # Exclude self to prevent infinite recursion
          macros = TextFilter.available_filter_types['macropost'].reject { |m| m == self }
          macros.inject(text) do |text, macro|
            macro.filtertext(blog, content, text, params)
          end
        end
      end

      class MacroPreExpander < TextFilterPlugin::MacroPre
        plugin_display_name 'MacroPre'
        plugin_description 'Macro expansion meta-filter (pre-markup)'

        def self.short_name
          'macropre'
        end

        def self.filtertext(blog, content, text, params)
          params[:filterparams]

          # Exclude self to prevent infinite recursion
          macros = TextFilter.available_filter_types['macropre'].reject { |m| m == self }
          macros.inject(text) do |text, macro|
            macro.filtertext(blog, content, text, params)
          end
        end
      end
    end
  end
end

# Re-register the macro expanders under their correct short names
TextFilterPlugin.filter_map['macropost'] = Typo::Textfilter::MacroPostExpander
TextFilterPlugin.filter_map['macropre'] = Typo::Textfilter::MacroPreExpander
