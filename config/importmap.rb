# Pin npm packages by running ./bin/importmap

# Note: The app uses both importmap (for Turbo/Stimulus) and Sprockets (for legacy JS)
# The "application" pin bootstraps Stimulus and loads controllers
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"

# Pin all controllers explicitly
pin "controllers", to: "controllers/index.js", preload: true
pin "controllers/application", to: "controllers/application.js", preload: true
pin "controllers/attachment_controller", to: "controllers/attachment_controller.js"
pin "controllers/autosave_controller", to: "controllers/autosave_controller.js"
pin "controllers/category_overlay_controller", to: "controllers/category_overlay_controller.js"
pin "controllers/dropdown_controller", to: "controllers/dropdown_controller.js"
pin "controllers/fade_out_controller", to: "controllers/fade_out_controller.js"
pin "controllers/flash_controller", to: "controllers/flash_controller.js"
pin "controllers/markdown_editor_controller", to: "controllers/markdown_editor_controller.js"
pin "controllers/sortable_controller", to: "controllers/sortable_controller.js"

# Marked.js for markdown preview rendering (lightweight, fast CDN)
pin "marked", to: "https://cdn.jsdelivr.net/npm/marked@12.0.0/lib/marked.esm.js"
