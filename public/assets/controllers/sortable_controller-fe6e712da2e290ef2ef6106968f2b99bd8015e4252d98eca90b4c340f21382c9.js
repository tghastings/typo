import { Controller } from "@hotwired/stimulus"

// Handles drag-and-drop sorting for sidebar items
// Replaces Scriptaculous Sortable
export default class extends Controller {
  static values = {
    url: String,
    handle: String  // Optional CSS selector for drag handle
  }

  connect() {
    this.makeSortable()
  }

  makeSortable() {
    const items = Array.from(this.element.children)

    items.forEach((item, index) => {
      item.draggable = true
      item.dataset.position = index

      item.addEventListener('dragstart', this.handleDragStart.bind(this))
      item.addEventListener('dragover', this.handleDragOver.bind(this))
      item.addEventListener('drop', this.handleDrop.bind(this))
      item.addEventListener('dragend', this.handleDragEnd.bind(this))
    })
  }

  handleDragStart(event) {
    this.draggedElement = event.currentTarget
    event.currentTarget.style.opacity = '0.4'
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/html', event.currentTarget.innerHTML)
  }

  handleDragOver(event) {
    if (event.preventDefault) {
      event.preventDefault()
    }
    event.dataTransfer.dropEffect = 'move'

    const target = event.currentTarget
    if (this.draggedElement !== target) {
      const rect = target.getBoundingClientRect()
      const midpoint = rect.top + (rect.height / 2)

      if (event.clientY < midpoint) {
        target.parentNode.insertBefore(this.draggedElement, target)
      } else {
        target.parentNode.insertBefore(this.draggedElement, target.nextSibling)
      }
    }

    return false
  }

  handleDrop(event) {
    if (event.stopPropagation) {
      event.stopPropagation()
    }
    return false
  }

  handleDragEnd(event) {
    event.currentTarget.style.opacity = '1'

    // Update positions and save to server
    this.updatePositions()
  }

  async updatePositions() {
    const items = Array.from(this.element.children)
    const ids = items.map(item => item.dataset.id || item.id).filter(Boolean)

    if (!this.urlValue || ids.length === 0) {
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ positions: ids })
      })

      if (!response.ok) {
        console.error('Failed to update positions:', response.statusText)
      }
    } catch (error) {
      console.error('Error updating positions:', error)
    }
  }
};
