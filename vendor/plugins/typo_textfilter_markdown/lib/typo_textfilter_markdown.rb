require 'kramdown'
require 'kramdown-parser-gfm'

class Typo
  class Textfilter
    class Markdown < TextFilterPlugin::Markup
      plugin_display_name "Markdown"
      plugin_description 'GitHub Flavored Markdown with fenced code blocks and syntax highlighting'

      def self.help_text
        %{
[Markdown](http://daringfireball.net/projects/markdown/) is a simple text-to-HTML converter that
turns common text idioms into HTML. This uses GitHub Flavored Markdown (GFM) which adds:

* **Fenced code blocks**: Use triple backticks with a language name for syntax highlighting:

        ```ruby
        def hello
          puts "Hello, World!"
        end
        ```

* **Paragraphs**: Start a new paragraph by skipping a line.
* **Italics**: Put text in *italics* by enclosing it in either \\* or \\_: `*italics*` turns into *italics*.
* **Bold**: Put text in **bold** by enclosing it in two \\*s: `**bold**` turns into **bold**.
* **Strikethrough**: Use ~~strikethrough~~ with double tildes.
* **Task lists**: Create checkboxes with `- [ ]` and `- [x]`.
* **Tables**: Create tables using pipes and dashes.
* **Autolinks**: URLs are automatically converted to links.
* **Block quotes**: Any paragraph (or line) that starts with a `>` is treated as a blockquote.
* **Hyperlinks**: You can create links like this: `[amazon's web site](http://www.amazon.com)`.
* **Lists**: Use asterisks (*) for bullets or numbers for numbered lists.

        }
      end

      def self.filtertext(blog, content, text, params)
        # Protect Typo macros from being processed by Kramdown
        escaped_macros = text.gsub(%r{(</?typo):}, '\1TYPO_MACRO_PLACEHOLDER')

        # Convert Markdown to HTML using Kramdown with GFM parser
        html = Kramdown::Document.new(
          escaped_macros,
          input: 'GFM',
          hard_wrap: false,
          syntax_highlighter: nil,  # Let Prism.js handle highlighting on the client
          auto_ids: true,
          entity_output: :as_char
        ).to_html

        # Remove notextile tags if present
        html = html.gsub(%r{</?notextile>}, '')

        # Restore Typo macros
        html.gsub(%r{(</?typo)TYPO_MACRO_PLACEHOLDER}, '\1:')
      end
    end
  end
end
