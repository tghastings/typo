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
    console.log('Rich editor controller connected')
    this.loadQuill()
  }

  async loadQuill() {
    // Quill is loaded globally via CDN in the layout
    // Just wait for it to be available
    if (typeof Quill === 'undefined') {
      // Wait a bit for Quill to load
      let attempts = 0
      while (typeof Quill === 'undefined' && attempts < 50) {
        await new Promise(resolve => setTimeout(resolve, 100))
        attempts++
      }

      if (typeof Quill === 'undefined') {
        console.error('Quill failed to load after 5 seconds')
        return
      }
    }

    this.initializeEditor()
  }

  initializeEditor() {
    if (this.quill) {
      console.log('Quill already initialized')
      return // Already initialized
    }

    console.log('Initializing Quill editor...', this.editorTarget)

    const toolbarOptions = this.getToolbarConfig()

    try {
      // Initialize Quill
      this.quill = new Quill(this.editorTarget, {
        theme: 'snow',
        placeholder: this.placeholderValue,
        modules: {
          toolbar: toolbarOptions
        }
      })

      console.log('Quill initialized successfully!', this.quill)

      // Attach Quill instance to the editor element for legacy code access
      this.editorTarget.quill = this.quill
      window.quillEditor = this.quill

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
    } catch (error) {
      console.error('Failed to initialize Quill:', error)
    }
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
}
