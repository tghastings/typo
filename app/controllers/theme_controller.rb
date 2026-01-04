# frozen_string_literal: true

class ThemeController < ContentController
  skip_forgery_protection only: %i[stylesheets javascript images]

  def stylesheets
    render_theme_item(:stylesheets, params[:filename], 'text/css; charset=utf-8')
  end

  def javascript
    render_theme_item(:javascript, params[:filename], 'text/javascript; charset=utf-8')
  end

  def images
    render_theme_item(:images, params[:filename])
  end

  def error
    head :not_found
  end

  def static_view_test; end

  private

  def render_theme_item(type, file, mime = nil)
    mime ||= mime_for(file)
    return render 'errors/404', status: 404, formats: [:html] if file.split(%r{[\\/]}).include?('..')

    src = this_blog.current_theme.path + "/#{type}/#{file}"
    return render plain: 'Not Found', status: 404 unless File.exist? src

    # Set proper content-type header explicitly
    response.headers['Content-Type'] = mime
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'

    send_data File.read(src), type: mime, disposition: 'inline'
  end

  def mime_for(filename)
    case filename.downcase
    when /\.js$/
      'text/javascript'
    when /\.css$/
      'text/css'
    when /\.gif$/
      'image/gif'
    when /(\.jpg|\.jpeg)$/
      'image/jpeg'
    when /\.png$/
      'image/png'
    when /\.swf$/
      'application/x-shockwave-flash'
    else
      'application/binary'
    end
  end
end
