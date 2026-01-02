import { Controller } from "@hotwired/stimulus"

// Shared drag state for cross-container dragging
if (!window.sortableDragState) {
  window.sortableDragState = { element: null }
}

// Handles drag-and-drop sorting for sidebar items
// Supports cross-container dragging (available <-> active)
export default class extends Controller {
  static values = {
    url: String,
    handle: String  // Optional CSS selector for drag handle
  }

  connect() {
    console.log('Sortable controller connected to:', this.element.id)
    this.makeSortable()
    // Allow container to receive drops
    this.element.addEventListener('dragover', this.handleContainerDragOver.bind(this))
    this.element.addEventListener('drop', this.handleContainerDrop.bind(this))
  }

  makeSortable() {
    const items = Array.from(this.element.children)

    items.forEach((item, index) => {
      item.draggable = true
      item.dataset.position = index
      item.style.cursor = 'grab'

      item.addEventListener('dragstart', this.handleDragStart.bind(this))
      item.addEventListener('dragover', this.handleDragOver.bind(this))
      item.addEventListener('drop', this.handleDrop.bind(this))
      item.addEventListener('dragend', this.handleDragEnd.bind(this))
    })
  }

  handleDragStart(event) {
    console.log('Drag started:', event.currentTarget.id)
    window.sortableDragState.element = event.currentTarget
    event.currentTarget.style.opacity = '0.4'
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', event.currentTarget.id)

    const spinner = document.getElementById('update_spinner')
    if (spinner) spinner.style.display = 'inline'
  }

  handleDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'

    const draggedElement = window.sortableDragState.element
    const target = event.currentTarget

    if (draggedElement && draggedElement !== target) {
      const rect = target.getBoundingClientRect()
      const midpoint = rect.top + (rect.height / 2)

      if (event.clientY < midpoint) {
        target.parentNode.insertBefore(draggedElement, target)
      } else {
        target.parentNode.insertBefore(draggedElement, target.nextSibling)
      }
    }

    return false
  }

  handleContainerDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  handleContainerDrop(event) {
    event.preventDefault()
    const draggedElement = window.sortableDragState.element

    // If dropped on empty container area, append to end
    if (draggedElement && event.target === this.element) {
      this.element.appendChild(draggedElement)
    }
    return false
  }

  handleDrop(event) {
    event.stopPropagation()
    event.preventDefault()
    return false
  }

  handleDragEnd(event) {
    event.currentTarget.style.opacity = '1'

    // Update positions and save to server
    this.saveActiveItems()

    setTimeout(() => {
      const spinner = document.getElementById('update_spinner')
      if (spinner) spinner.style.display = 'none'
    }, 500)

    window.sortableDragState.element = null
  }

  async saveActiveItems() {
    // Only save from the active container
    const activeContainer = document.getElementById('active')
    if (!activeContainer) return

    const items = Array.from(activeContainer.children).filter(el => el.id)
    const activeIds = items.map(item => {
      const id = item.id
      if (id.startsWith('active_')) return id.replace('active_', '')
      if (id.startsWith('available_')) return id.replace('available_', '')
      return id
    })

    const url = activeContainer.dataset.sortableUrlValue
    if (!url) return

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content || '',
          'Accept': 'text/javascript, application/javascript, */*'
        },
        body: activeIds.map(id => `active[]=${encodeURIComponent(id)}`).join('&')
      })

      if (!response.ok) {
        console.error('Failed to update positions:', response.statusText)
      }
    } catch (error) {
      console.error('Error updating positions:', error)
    }
  }
}
