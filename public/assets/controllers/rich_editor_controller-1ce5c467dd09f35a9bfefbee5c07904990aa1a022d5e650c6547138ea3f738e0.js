import { Controller } from "@hotwired/stimulus"

// Modern rich text editor controller using Quill
// Replaces CKEditor with a lightweight, Turbo-compatible editor
export default class extends Controller {
  static targets = ["editor", "input"]
  static values = {
    placeholder: { type: String, default: "Start writing..." },
    toolbar: { type: String, default: "full" }
  }

  connect() {
    this.loadQuill()
  }

  async loadQuill() {
    // Load Quill dynamically
    if (typeof Quill === 'undefined') {
      // Import Quill CSS
      if (!document.querySelector('link[href*="quill"]')) {
        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = 'https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.snow.css'
        document.head.appendChild(link)
      }

      // Import Quill JS
      try {
        const module = await import('quill')
        window.Quill = module.default || module
      } catch (error) {
        console.error('Failed to load Quill:', error)
        return
      }
    }

    this.initializeEditor()
  }

  initializeEditor() {
    if (this.quill) {
      return // Already initialized
    }

    const toolbarOptions = this.getToolbarConfig()

    // Initialize Quill
    this.quill = new Quill(this.editorTarget, {
      theme: 'snow',
      placeholder: this.placeholderValue,
      modules: {
        toolbar: toolbarOptions
      }
    })

    // Set initial content from hidden input
    if (this.hasInputTarget && this.inputTarget.value) {
      this.quill.root.innerHTML = this.inputTarget.value
    }

    // Update hidden input on text change
    this.quill.on('text-change', () => {
      if (this.hasInputTarget) {
        this.inputTarget.value = this.quill.root.innerHTML
        // Trigger change event for autosave
        this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
      }
    })

    // Make Quill work with Turbo
    this.element.setAttribute('data-turbo-permanent', '')
  }

  getToolbarConfig() {
    if (this.toolbarValue === 'simple') {
      return [
        ['bold', 'italic', 'underline'],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        ['link']
      ]
    }

    // Full toolbar
    return [
      [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
      ['bold', 'italic', 'underline', 'strike'],
      [{ 'list': 'ordered'}, { 'list': 'bullet' }],
      [{ 'indent': '-1'}, { 'indent': '+1' }],
      [{ 'align': [] }],
      ['blockquote', 'code-block'],
      ['link', 'image'],
      [{ 'color': [] }, { 'background': [] }],
      ['clean']
    ]
  }

  disconnect() {
    if (this.quill) {
      // Save content before disconnect
      if (this.hasInputTarget) {
        this.inputTarget.value = this.quill.root.innerHTML
      }
    }
  }

  // Public method to get HTML content
  getHTML() {
    return this.quill ? this.quill.root.innerHTML : ''
  }

  // Public method to set HTML content
  setHTML(html) {
    if (this.quill) {
      this.quill.root.innerHTML = html
    }
  }

  // Public method to get plain text
  getText() {
    return this.quill ? this.quill.getText() : ''
  }
};
