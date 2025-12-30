import { Controller } from "@hotwired/stimulus"

// Handles automatic saving of article editor content every 30 seconds
// Replaces Prototype's Form.Observer
export default class extends Controller {
  static targets = ["form", "status"]
  static values = {
    interval: { type: Number, default: 30000 },  // 30 seconds
    url: String
  }

  connect() {
    this.startAutosave()
    this.updateStatus("Autosave enabled")
  }

  disconnect() {
    this.stopAutosave()
  }

  startAutosave() {
    this.stopAutosave()  // Clear any existing timer
    this.timer = setInterval(() => this.save(), this.intervalValue)
  }

  stopAutosave() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  async save() {
    try {
      // Sync CKEditor content if it exists
      if (typeof CKEDITOR !== 'undefined' && CKEDITOR.instances.article__body_and_extended_editor) {
        const content = CKEDITOR.instances.article__body_and_extended_editor.getData()
        const textarea = document.getElementById('article__body_and_extended_editor')
        if (textarea) {
          textarea.value = content
        }
      }

      const formData = new FormData(this.formTarget)
      const url = this.urlValue || this.formTarget.action.replace(/\/(new|edit).*$/, '/autosave')

      this.updateStatus("Saving...")

      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html, application/json'
        }
      })

      if (response.ok) {
        const contentType = response.headers.get('content-type')

        if (contentType && contentType.includes('turbo-stream')) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        }

        this.updateStatus("Saved at " + new Date().toLocaleTimeString())
      } else {
        this.updateStatus("Save failed")
      }
    } catch (error) {
      console.error("Autosave error:", error)
      this.updateStatus("Save error")
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  // Manual save trigger
  saveNow(event) {
    event.preventDefault()
    this.save()
  }
}
