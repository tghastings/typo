# Pin npm packages by running ./bin/importmap

# Note: The app uses both importmap (for Turbo/Stimulus) and Sprockets (for legacy JS)
# The "application" pin bootstraps Stimulus and loads controllers
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# jQuery - Required for legacy admin UI
pin "jquery", to: "https://code.jquery.com/jquery-3.7.1.min.js"

# Quill - Modern rich text editor (replacing CKEditor)
pin "quill", to: "https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js"
