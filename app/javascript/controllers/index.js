// Import and register all controllers
import { application } from "controllers/application"

// Import all controllers
import AttachmentController from "controllers/attachment_controller"
import AutosaveController from "controllers/autosave_controller"
import CategoryOverlayController from "controllers/category_overlay_controller"
import DropdownController from "controllers/dropdown_controller"
import FadeOutController from "controllers/fade_out_controller"
import FlashController from "controllers/flash_controller"
import MarkdownEditorController from "controllers/markdown_editor_controller"
import SortableController from "controllers/sortable_controller"

// Register controllers
application.register("attachment", AttachmentController)
application.register("autosave", AutosaveController)
application.register("category-overlay", CategoryOverlayController)
application.register("dropdown", DropdownController)
application.register("fade-out", FadeOutController)
application.register("flash", FlashController)
application.register("markdown-editor", MarkdownEditorController)
application.register("sortable", SortableController)

// Start the application
try {
  application.start()
} catch (err) {
  console.error('[Stimulus] Failed to start:', err)
}
