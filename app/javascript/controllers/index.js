// Import and register all controllers
console.log('[Stimulus] Starting controller imports...')
import { application } from "controllers/application"
console.log('[Stimulus] Application imported')

// Import all controllers
import AttachmentController from "controllers/attachment_controller"
import AutosaveController from "controllers/autosave_controller"
import CategoryOverlayController from "controllers/category_overlay_controller"
import DropdownController from "controllers/dropdown_controller"
import FadeOutController from "controllers/fade_out_controller"
import FlashController from "controllers/flash_controller"
import MarkdownEditorController from "controllers/markdown_editor_controller"
import SortableController from "controllers/sortable_controller"
console.log('[Stimulus] All controllers imported')

// Register controllers
application.register("attachment", AttachmentController)
application.register("autosave", AutosaveController)
application.register("category-overlay", CategoryOverlayController)
application.register("dropdown", DropdownController)
application.register("fade-out", FadeOutController)
application.register("flash", FlashController)
application.register("markdown-editor", MarkdownEditorController)
application.register("sortable", SortableController)
console.log('[Stimulus] All controllers registered')

// Start the application immediately
// ES modules are deferred so DOM is ready when this runs
console.log('[Stimulus] Document readyState:', document.readyState)

try {
  application.start()
  console.log('[Stimulus] Application started successfully')

  // Log connected controllers after a short delay to allow connections
  setTimeout(() => {
    const elements = document.querySelectorAll('[data-controller]')
    const status = []
    elements.forEach(el => {
      const ids = el.dataset.controller.split(' ')
      ids.forEach(id => {
        const ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, id)
        status.push(ctrl ? `${id}:connected` : `${id}:NOT connected`)
      })
    })
    console.log('[Stimulus] Connected controllers:', status)
  }, 100)
} catch (err) {
  console.error('[Stimulus] Failed to start:', err)
}
