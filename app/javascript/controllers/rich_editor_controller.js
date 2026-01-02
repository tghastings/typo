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
    // Don't initialize if parent is hidden (editor not selected)
    if (this.element.offsetParent === null) {
      this.deferred = true
      return
    }
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

    try {
      // Initialize Quill
      this.quill = new Quill(this.editorTarget, {
        theme: 'snow',
        placeholder: this.placeholderValue,
        modules: {
          toolbar: toolbarOptions
        }
      })

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
      // Quill initialization failed
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

    // Full toolbar with custom Amazon button
    return {
      container: [
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        ['bold', 'italic', 'underline', 'strike'],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        [{ 'indent': '-1'}, { 'indent': '+1' }],
        [{ 'align': [] }],
        ['blockquote', 'code-block'],
        ['link', 'image', 'amazon'],
        [{ 'color': [] }, { 'background': [] }],
        ['clean']
      ],
      handlers: {
        'amazon': () => this.insertAmazonProduct()
      }
    }
  }

  insertAmazonProduct() {
    const asin = prompt('Enter Amazon ASIN (10-character product ID from URL):')
    if (!asin) return

    const title = prompt('Enter book/product title:')
    if (!title) return

    const linkText = prompt('Enter link text (or leave blank to use title):', title)
    const displayText = linkText || title

    const amazonTag = `<typo:amazon asin="${asin}" title="${title}">${displayText}</typo:amazon>`

    // Insert as plain text so it's visible in the editor
    // The text filter will process it when the article is rendered
    const range = this.quill.getSelection(true)
    this.quill.insertText(range.index, amazonTag)
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
