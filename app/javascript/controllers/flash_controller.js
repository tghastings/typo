import { Controller } from "@hotwired/stimulus"

// Handles flash message display and auto-dismiss
// Replaces Growler library from Prototype
export default class extends Controller {
  static values = {
    dismissAfter: { type: Number, default: 5000 }  // Auto-dismiss after 5 seconds
  }

  connect() {
    if (this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.dismissAfterValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    this.element.style.transition = "opacity 300ms ease-out"
    this.element.style.opacity = "0"

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  // Allow manual dismissal
  close(event) {
    event.preventDefault()
    this.dismiss()
  }
}
