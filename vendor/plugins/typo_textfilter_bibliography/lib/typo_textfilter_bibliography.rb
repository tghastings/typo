# frozen_string_literal: true

# Bibliography text filter - adds academic-style citations to links
# Adds superscript numbers [1], [2] to links and creates a references section
class Typo
  class Textfilter
    class Bibliography < TextFilterPlugin::PostProcess
      plugin_display_name 'Bibliography'
      plugin_description 'Adds academic-style numbered references to links with a bibliography at the end'

      def self.filtertext(blog, content, text, params)
        return '' if text.blank?

        # Track URLs and their reference numbers
        url_refs = {}
        ref_counter = 0

        # Find all links and add superscript references
        # Match <a href="...">...</a> but skip anchor-only links
        result = text.gsub(/<a\s+([^>]*href=["']([^"']+)["'][^>]*)>(.*?)<\/a>/mi) do |match|
          full_attrs = $1
          url = $2
          link_text = $3

          # Skip internal anchor links and mailto links
          if url.start_with?('#') || url.start_with?('mailto:') || url.start_with?('javascript:')
            match
          else
            # Get or assign reference number
            if url_refs[url]
              ref_num = url_refs[url][:num]
            else
              ref_counter += 1
              ref_num = ref_counter
              url_refs[url] = { num: ref_num, url: url }
            end

            # Return link with superscript reference
            %(<a #{full_attrs}>#{link_text}</a><sup class="bibliography-ref">[#{ref_num}]</sup>)
          end
        end

        # If no external links found, return original text
        return result if url_refs.empty?

        # Build bibliography section
        bibliography = build_bibliography(url_refs)

        result + bibliography
      end

      def self.build_bibliography(url_refs)
        entries = url_refs.values.sort_by { |ref| ref[:num] }

        lines = ['', '<div class="bibliography">', '<h3>References</h3>', '<ol class="bibliography-list">']

        entries.each do |ref|
          domain = extract_domain(ref[:url])
          lines << %(<li value="#{ref[:num]}"><a href="#{ref[:url]}" class="bibliography-link" target="_blank" rel="noopener">#{domain}</a></li>)
        end

        lines << '</ol>'
        lines << '</div>'
        lines.join("\n")
      end

      def self.extract_domain(url)
        uri = URI.parse(url)
        host = uri.host || url
        # Remove www. prefix for cleaner display
        host.sub(/\Awww\./, '')
      rescue URI::InvalidURIError
        url
      end
    end
  end
end
