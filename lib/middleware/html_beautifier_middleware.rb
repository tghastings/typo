# frozen_string_literal: true

# Middleware to beautify HTML output for a pristine view-source experience
class HtmlBeautifierMiddleware
  BLOCK_TAGS = %w[
    html head body
    header footer main aside nav section article div
    h1 h2 h3 h4 h5 h6
    p ul ol li dl dt dd
    table thead tbody tfoot tr th td
    form fieldset legend
    figure figcaption
    blockquote address
    script style link meta
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if html_response?(headers) && !skip_beautification?(env)
      body = extract_body(response)
      if body.present?
        begin
          beautified = beautify_html(body)
          headers['Content-Length'] = beautified.bytesize.to_s
          response = [beautified]
        rescue StandardError => e
          Rails.logger.warn "HTML Beautifier failed: #{e.message}"
        end
      end
    end

    [status, headers, response]
  end

  private

  def html_response?(headers)
    headers['Content-Type'].to_s.include?('text/html')
  end

  def skip_beautification?(env)
    path = env['PATH_INFO'].to_s
    path.start_with?('/admin') ||
      env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' ||
      env['HTTP_ACCEPT'].to_s.include?('turbo-stream')
  end

  def extract_body(response)
    body = String.new
    response.each { |part| body << part.to_s }
    response.close if response.respond_to?(:close)
    body
  end

  def beautify_html(html)
    # Step 1: Preserve pre/code/textarea content exactly
    preserved = {}
    counter = 0
    working = html.gsub(%r{<(pre|code|textarea)(\s[^>]*)?>.*?</\1>}mi) do |match|
      key = "___PRESERVE_#{counter}___"
      preserved[key] = match
      counter += 1
      key
    end

    # Step 2: Normalize whitespace
    working = working.gsub(/>\s+</, '><').gsub(/\s+/, ' ')

    # Step 3: Add newlines around block elements
    block_pattern = BLOCK_TAGS.join('|')
    working = working.gsub(%r{<(#{block_pattern})(\s|>|/)}i, "\n<\\1\\2")
    working = working.gsub(%r{</(#{block_pattern})>}i, "</\\1>\n")
    working = working.gsub(/<!DOCTYPE[^>]*>/i) { |m| "#{m}\n" }

    # Step 4: Split and indent
    lines = working.split("\n").map(&:strip).reject(&:empty?)
    indent_level = 0
    result = []

    lines.each do |line|
      # Check for closing tag
      if line =~ %r{^</(html|head|body|header|footer|main|aside|nav|section|article|div|ul|ol|dl|table|thead|tbody|tfoot|form|fieldset|figure)>}i
        indent_level -= 1
        indent_level = 0 if indent_level.negative?
      end

      # Add line with current indent
      result << (('  ' * indent_level) + line)

      # Check for opening tag that needs indent increase
      block_tags = /^<(html|head|body|header|footer|main|aside|nav|section|article|div|ul|ol|dl|table|thead|tbody|tfoot|form|fieldset|figure)(\s|>)/i
      next unless line =~ block_tags

      indent_level += 1 unless line =~ %r{</\w+>$} || line =~ %r{/>$}
    end

    output = result.join("\n")

    # Step 5: Restore preserved content exactly as-is (don't modify code blocks)
    preserved.each do |key, content|
      output = output.sub(key, content)
    end

    "#{output}\n"
  end
end
