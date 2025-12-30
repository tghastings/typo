import { Controller } from "@hotwired/stimulus"

// Handles inline category creation overlay/modal
// Replaces Ajax.Request modal from Prototype
export default class extends Controller {
  static targets = ["modal", "form", "backdrop"]

  show(event) {
    event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.style.display = 'block'
    }

    if (this.hasBackdropTarget) {
      this.backdropTarget.style.display = 'block'
    }

    // Focus on first input
    if (this.hasFormTarget) {
      const firstInput = this.formTarget.querySelector('input[type="text"]')
      if (firstInput) {
        firstInput.focus()
      }
    }
  }

  hide(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.hasModalTarget) {
      this.modalTarget.style.display = 'none'
    }

    if (this.hasBackdropTarget) {
      this.backdropTarget.style.display = 'none'
    }
  }

  async submit(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(this.formTarget.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.hide()
        this.formTarget.reset()
      } else {
        const errorText = await response.text()
        alert('Failed to create category: ' + errorText)
      }
    } catch (error) {
      console.error('Category creation error:', error)
      alert('Error creating category: ' + error.message)
    }
  }

  // Close on backdrop click
  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.hide()
    }
  }

  // Close on ESC key
  closeOnEscape(event) {
    if (event.key === 'Escape') {
      this.hide()
    }
  }
};
