class Typo
  class Textfilter
    class Pdf < TextFilterPlugin::MacroPost
      plugin_display_name "PDF Slideshow"
      plugin_description "Embed PDF files as interactive slideshows with keyboard navigation"

      def self.help_text
        %{
You can use `<typo:pdf>` to embed PDF files as interactive slideshows directly in your articles.

Example:

    <typo:pdf src="presentation.pdf"/>

The slideshow supports keyboard navigation:
- **Arrow Left/Right**: Navigate between slides
- **Space**: Next slide
- **Escape**: Exit fullscreen
- **F**: Enter fullscreen

## Attributes

* **src** (required): The PDF filename in `/files/` or a full URL to an external PDF.
* **title**: Optional title displayed above the slideshow.
* **width**: Custom width in pixels (default: 100% of container).
* **height**: Custom height in pixels (default: 500px).
* **autoplay**: Set to "true" to auto-advance slides.
* **interval**: Autoplay interval in milliseconds (default: 5000).
* **start**: Starting slide number (default: 1).

## Examples

Basic usage:

    <typo:pdf src="my-presentation.pdf"/>

With title and custom size:

    <typo:pdf src="slides.pdf" title="My Talk" width="800" height="600"/>

Autoplay mode:

    <typo:pdf src="slides.pdf" autoplay="true" interval="3000"/>

External PDF:

    <typo:pdf src="https://example.com/document.pdf"/>
}
      end

      def self.macrofilter(blog, content, attrib, params, text = "")
        src = attrib['src']

        return error_html('No PDF source specified') if src.blank?

        # Build PDF URL
        pdf_url = build_pdf_url(blog, src)

        # Extract optional attributes with HTML escaping
        title = escape_html(attrib['title'])
        width = attrib['width']
        height = attrib['height'] || '500'
        autoplay = attrib['autoplay'] == 'true'
        interval = attrib['interval'] || '5000'
        start_page = attrib['start'] || '1'

        # Inject required assets via whiteboard
        set_whiteboard(blog, content) unless content.nil?

        # Build and return HTML
        build_slideshow_html(
          pdf_url: escape_html(pdf_url),
          title: title,
          width: width,
          height: height,
          autoplay: autoplay,
          interval: interval,
          start_page: start_page
        )
      end

      private

      def self.build_pdf_url(blog, src)
        if src =~ /\Ahttps?:\/\//i
          # External URL - use as-is
          src
        else
          # Use the /files/ route which serves from Active Storage
          "/files/#{src}"
        end
      end

      def self.escape_html(text)
        return nil if text.nil?
        CGI.escapeHTML(text.to_s)
      end

      def self.error_html(message)
        %{<div class="pdf-slideshow-error">
          <p><strong>PDF Slideshow Error:</strong> #{escape_html(message)}</p>
        </div>}
      end

      def self.set_whiteboard(blog, content)
        # Use cache-busting query param to avoid stale CSS
        cache_buster = Time.now.to_i
        content.whiteboard['page_header_pdf_slideshow'] = <<-HTML
          <link href="/stylesheets/pdf_slideshow.css?v=#{cache_buster}" media="all" rel="stylesheet" type="text/css" />
          <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
          <script>
            if (typeof pdfjsLib !== 'undefined') {
              pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
            }
          </script>
        HTML
      end

      def self.build_slideshow_html(pdf_url:, title:, width:, height:, autoplay:, interval:, start_page:)
        style = []
        style << "width: #{width}px" if width
        style << "height: #{height}px" if height
        style_attr = style.any? ? %{ style="#{style.join('; ')}"} : ''

        <<-HTML
        <div class="pdf-slideshow-container"#{style_attr}
             data-controller="pdf-slideshow"
             data-pdf-slideshow-src-value="#{pdf_url}"
             data-pdf-slideshow-autoplay-value="#{autoplay}"
             data-pdf-slideshow-interval-value="#{interval}"
             data-pdf-slideshow-start-page-value="#{start_page}">

          <div class="pdf-slideshow-frame">
            #{title_html(title)}
            <div class="pdf-slideshow-viewport" data-pdf-slideshow-target="viewport">
              <canvas data-pdf-slideshow-target="canvas"></canvas>
              <div class="pdf-slideshow-loading" data-pdf-slideshow-target="loading">
                <div class="pdf-slideshow-spinner"></div>
                <span>Loading...</span>
              </div>
            </div>
          </div>

          <div class="pdf-slideshow-controls">
            <button type="button"
                    class="pdf-slideshow-btn pdf-slideshow-prev"
                    data-action="pdf-slideshow#previousPage"
                    data-pdf-slideshow-target="prevBtn"
                    aria-label="Previous slide">
              <svg viewBox="0 0 24 24" width="24" height="24">
                <path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"/>
              </svg>
            </button>

            <div class="pdf-slideshow-counter" data-pdf-slideshow-target="counter">
              <span data-pdf-slideshow-target="currentPage">1</span>
              <span class="pdf-slideshow-separator">/</span>
              <span data-pdf-slideshow-target="totalPages">?</span>
            </div>

            <button type="button"
                    class="pdf-slideshow-btn pdf-slideshow-next"
                    data-action="pdf-slideshow#nextPage"
                    data-pdf-slideshow-target="nextBtn"
                    aria-label="Next slide">
              <svg viewBox="0 0 24 24" width="24" height="24">
                <path d="M8.59 16.59L10 18l6-6-6-6-1.41 1.41L13.17 12z"/>
              </svg>
            </button>

            <button type="button"
                    class="pdf-slideshow-btn pdf-slideshow-fullscreen"
                    data-action="pdf-slideshow#toggleFullscreen"
                    aria-label="Toggle fullscreen">
              <svg viewBox="0 0 24 24" width="24" height="24" data-pdf-slideshow-target="fullscreenIcon">
                <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/>
              </svg>
            </button>
          </div>

          <div class="pdf-slideshow-keyboard-hint">
            Use arrow keys or space to navigate. Press F for fullscreen.
          </div>
        </div>
        HTML
      end

      def self.title_html(title)
        return '' if title.blank?
        %{<div class="pdf-slideshow-title">#{title}</div>}
      end
    end
  end
end
