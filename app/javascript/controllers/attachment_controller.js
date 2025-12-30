import { Controller } from "@hotwired/stimulus"

// Handles file attachment uploads and removal in admin interface
// Replaces Ajax.Request for attachment management
export default class extends Controller {
  static targets = ["list", "input", "progress"]

  async upload(event) {
    const files = event.target.files
    if (!files || files.length === 0) return

    const formData = new FormData()
    Array.from(files).forEach(file => {
      formData.append('attachments[]', file)
    })

    try {
      this.showProgress()

      const response = await fetch(this.element.dataset.uploadUrl, {
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
        this.clearInput()
      } else {
        alert('Upload failed: ' + response.statusText)
      }
    } catch (error) {
      console.error('Upload error:', error)
      alert('Upload error: ' + error.message)
    } finally {
      this.hideProgress()
    }
  }

  async remove(event) {
    event.preventDefault()

    if (!confirm('Are you sure you want to remove this attachment?')) {
      return
    }

    const url = event.currentTarget.href

    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        alert('Remove failed: ' + response.statusText)
      }
    } catch (error) {
      console.error('Remove error:', error)
      alert('Remove error: ' + error.message)
    }
  }

  showProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.style.display = 'block'
    }
  }

  hideProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.style.display = 'none'
    }
  }

  clearInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }
  }
}
