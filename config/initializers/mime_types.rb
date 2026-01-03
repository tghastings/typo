# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register_alias "application/xml",     :googlesitemap
Mime::Type.register       "application/rsd+xml", :rsd

# Ensure CSS files are served with correct MIME type
Rack::Mime::MIME_TYPES['.css'] = 'text/css'