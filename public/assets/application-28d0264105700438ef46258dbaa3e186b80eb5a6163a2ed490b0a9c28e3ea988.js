// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// Note: Prototype.js compatibility patches are in the layout (run BEFORE Prototype.js loads)
console.log('application.js: Starting imports...')

import "@hotwired/turbo-rails"
console.log('application.js: Turbo loaded')

import "controllers"
console.log('application.js: Controllers loaded')

// DISABLE Turbo Drive - this app uses Prototype.js which doesn't work with Turbo's
// partial page replacements. Turbo Drive intercepts clicks and does AJAX navigation,
// but Prototype.js scripts expect full page loads.
// Turbo Frames and Streams still work if needed.
Turbo.session.drive = false
console.log('Turbo Drive disabled for Prototype.js compatibility');
