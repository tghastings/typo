import { Controller } from "@hotwired/stimulus"

// Handles dropdown menu toggling in admin interface
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close dropdown when clicking outside
    this.boundClose = this.closeOnClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const menu = this.menuTarget
    const isOpen = menu.style.display !== "none" && menu.style.display !== ""

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.style.display = "block"
    document.addEventListener("click", this.boundClose)
  }

  close() {
    this.menuTarget.style.display = "none"
    document.removeEventListener("click", this.boundClose)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
