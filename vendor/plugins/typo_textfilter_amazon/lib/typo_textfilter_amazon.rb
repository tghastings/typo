class Typo
  class Textfilter
    class Amazon < TextFilterPlugin::MacroPost
      plugin_display_name "Amazon"
      plugin_description "Extract Amazon product ASINs for the Amazon sidebar"

      # Match Amazon product URLs and extract ASIN and optional title from URL slug
      # Handles URLs like:
      #   https://www.amazon.com/dp/B0FCSM5T7M
      #   https://www.amazon.com/Product-Name/dp/B0FCSM5T7M/ref=...
      #   https://www.amazon.com/gp/product/B0FCSM5T7M
      AMAZON_URL_REGEX = %r{
        https?://(?:www\.)?amazon\.com/
        (?:([^/]+)/)?         # Optional product title slug (captured)
        (?:[^/]+/)*?          # Other optional path segments
        (?:
          dp/|
          gp/product/|
          exec/obidos/ASIN/|
          o/ASIN/|
          gp/aw/d/
        )
        ([A-Z0-9]{10})        # ASIN (10 alphanumeric chars)
      }xi

      def self.help_text
        %{
You can use `<typo:amazon>` to reference Amazon products. Example:

    <typo:amazon asin="0596516177" title="The Ruby Programming Language">Check out this book!</typo:amazon>

This will create a link to the Amazon product and make it available to the Amazon sidebar with the book title.

You can also just include Amazon URLs in your content and they will be automatically detected:

    Check out this book: https://www.amazon.com/dp/0596516177

The ASIN is the 10-character product identifier found in Amazon URLs.
}
      end

      # Override filtertext to also scan for Amazon URLs (not just <typo:amazon> tags)
      def self.filtertext(blog, content, text, params)
        # First, run the standard macro processing for <typo:amazon> tags
        text = super(blog, content, text, params)

        # Then scan for Amazon URLs and extract ASINs
        if content
          text.scan(AMAZON_URL_REGEX).each do |match|
            title_slug, asin = match
            next unless asin

            content.whiteboard[:amazon_products] ||= {}
            unless content.whiteboard[:amazon_products][asin]
              # Detect Audible products from URL
              is_audible = title_slug&.match?(/\bAudible\b/i)

              # Don't use URL slug as title - it's unreliable
              # User should use <typo:amazon title="..."> for proper titles
              content.whiteboard[:amazon_products][asin] = { title: nil, audible: is_audible }
            end
          end
        end

        text
      end

      def self.macrofilter(blog, content, attrib, params, text = "")
        asin = attrib['asin']
        return text if asin.blank?

        title = attrib['title']

        # Store ASIN and title in whiteboard for Amazon sidebar
        if content
          content.whiteboard[:amazon_products] ||= {}
          content.whiteboard[:amazon_products][asin] = { title: title }
        end

        # Generate link to Amazon product - use associate_id from Amazon sidebar config
        amazon_sidebar = Sidebar.where(type: 'AmazonSidebar').first
        associate_id = amazon_sidebar&.config&.dig('associate_id') || 'justasummary-20'
        url = "https://www.amazon.com/dp/#{asin}?tag=#{associate_id}"

        if text.present?
          %{<a href="#{url}" class="amazon-product" rel="nofollow">#{text}</a>}
        else
          display = title.present? ? title : "Amazon Product #{asin}"
          %{<a href="#{url}" class="amazon-product" rel="nofollow">#{display}</a>}
        end
      end
    end
  end
end
