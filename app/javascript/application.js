// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "./controllers"

// Configure Turbo
Turbo.session.drive = true

// Turbo configuration for legacy compatibility
document.addEventListener('turbo:load', () => {
  // Re-initialize calendar date select if needed
  if (typeof _calendar_date_select !== 'undefined') {
    _calendar_date_select.load()
  }
})
