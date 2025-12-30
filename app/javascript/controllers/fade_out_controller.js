import { Controller } from "@hotwired/stimulus"

// Handles fade-out animations for element removal
// Replaces Scriptaculous Effect.Fade
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 300 },  // Duration in milliseconds
    delay: { type: Number, default: 0 }        // Delay before starting fade
  }

  connect() {
    // Auto-fade if data-auto-fade is set
    if (this.element.dataset.autoFade === 'true') {
      this.fadeOut()
    }
  }

  fadeOut(event) {
    if (event) {
      event.preventDefault()
    }

    setTimeout(() => {
      this.element.style.transition = `opacity ${this.durationValue}ms ease-out`
      this.element.style.opacity = '0'

      setTimeout(() => {
        this.element.remove()
      }, this.durationValue)
    }, this.delayValue)
  }

  fadeIn(event) {
    if (event) {
      event.preventDefault()
    }

    this.element.style.opacity = '0'
    this.element.style.display = 'block'

    setTimeout(() => {
      this.element.style.transition = `opacity ${this.durationValue}ms ease-in`
      this.element.style.opacity = '1'
    }, 10)  // Small delay to ensure display:block is applied first
  }

  // Toggle visibility with fade
  toggle(event) {
    if (event) {
      event.preventDefault()
    }

    const isVisible = this.element.style.opacity !== '0' &&
                     this.element.style.display !== 'none'

    if (isVisible) {
      this.fadeOut()
    } else {
      this.fadeIn()
    }
  }

  // Fade out and remove (alias for fadeOut for clarity)
  fadeAndRemove(event) {
    this.fadeOut(event)
  }
}
