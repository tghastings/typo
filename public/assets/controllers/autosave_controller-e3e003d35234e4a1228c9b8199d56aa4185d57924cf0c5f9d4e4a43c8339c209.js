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
    // Only start autosave if we have a form target
    if (this.hasFormTarget) {
      this.startAutosave()
      this.updateStatus("Autosave enabled")
    } else {
      // Try to find the form as a parent element
      this.formElement = this.element.closest('form')
      if (this.formElement) {
        this.startAutosave()
        this.updateStatus("Autosave enabled")
      }
    }
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

  get form() {
    return this.hasFormTarget ? this.formTarget : this.formElement
  }

  async save() {
    const form = this.form
    if (!form) {
      return // No form available
    }

    try {
      // Sync CodeMirror/Quill content to hidden inputs if they exist
      // (Editors should handle their own syncing via input events)

      const formData = new FormData(form)
      const url = this.urlValue || form.action.replace(/\/(new|edit).*$/, '/autosave')

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
};
