import { Controller } from "@hotwired/stimulus"

// Full-featured markdown editor with CodeMirror 5 syntax highlighting and preview
// CodeMirror is loaded globally via CDN in the layout
export default class extends Controller {
  static targets = ["editor", "input", "toolbar", "preview"]

  static values = {
    uploadUrl: String,
    textFilter: { type: String, default: "markdown" }
  }

  connect() {
    this.previewVisible = false
    this.initializeEditor()
  }

  disconnect() {
    if (this.cm) {
      this.cm.toTextArea()
    }
  }

  initializeEditor() {
    // Get initial content from hidden input
    const initialContent = this.hasInputTarget ? this.inputTarget.value : ""

    // Clear loading message
    this.editorTarget.innerHTML = ""

    // Check if CodeMirror is available
    if (typeof CodeMirror !== "undefined") {
      this.initializeCodeMirror(initialContent)
    } else {
      console.warn("CodeMirror not loaded, falling back to textarea")
      this.initializeFallbackEditor(initialContent)
    }

    // Create preview pane (hidden initially)
    this.previewPane = document.createElement("div")
    this.previewPane.className = "markdown-preview"
    this.previewPane.style.display = "none"
    this.editorTarget.parentNode.insertBefore(this.previewPane, this.editorTarget.nextSibling)

    this.initialized = true
  }

  initializeCodeMirror(initialContent) {
    // Create a textarea for CodeMirror to enhance
    const textarea = document.createElement("textarea")
    textarea.value = initialContent
    textarea.className = "markdown-textarea"
    this.editorTarget.appendChild(textarea)

    // Initialize CodeMirror
    this.cm = CodeMirror.fromTextArea(textarea, {
      mode: "gfm", // GitHub Flavored Markdown
      theme: "default",
      lineNumbers: true,
      lineWrapping: true,
      autofocus: false,
      tabSize: 2,
      indentWithTabs: false,
      extraKeys: {
        "Ctrl-B": () => this.insertBold(),
        "Cmd-B": () => this.insertBold(),
        "Ctrl-I": () => this.insertItalic(),
        "Cmd-I": () => this.insertItalic(),
        "Ctrl-K": () => this.insertLink(),
        "Cmd-K": () => this.insertLink(),
        "Ctrl-P": () => this.togglePreview(),
        "Cmd-P": () => this.togglePreview(),
        "Tab": (cm) => {
          cm.replaceSelection("  ")
        }
      }
    })

    // Set editor height
    this.cm.setSize(null, 400)

    // Sync changes to hidden input
    this.cm.on("change", () => {
      this.syncToHiddenInput()
      if (this.previewVisible) {
        this.updatePreview()
      }
    })

    // Handle drag and drop for images
    this.cm.on("drop", (cm, event) => this.handleDrop(event))
    this.cm.on("paste", (cm, event) => this.handlePaste(event))

    console.log("CodeMirror markdown editor initialized with syntax highlighting")
  }

  // Fallback to simple textarea if CodeMirror fails to load
  initializeFallbackEditor(initialContent) {
    this.textarea = document.createElement("textarea")
    this.textarea.className = "markdown-textarea"
    this.textarea.value = initialContent
    this.textarea.placeholder = "Write your content using Markdown..."

    this.textarea.addEventListener("input", () => {
      this.syncToHiddenInput()
      if (this.previewVisible) {
        this.updatePreview()
      }
    })

    this.textarea.addEventListener("keydown", (e) => this.handleTextareaKeydown(e))
    this.editorTarget.appendChild(this.textarea)
  }

  handleTextareaKeydown(e) {
    if (e.key === "Tab") {
      e.preventDefault()
      this.insertTextAtCursor("  ")
      return
    }

    if (e.ctrlKey || e.metaKey) {
      switch (e.key.toLowerCase()) {
        case "b":
          e.preventDefault()
          this.insertBold()
          break
        case "i":
          e.preventDefault()
          this.insertItalic()
          break
        case "k":
          e.preventDefault()
          this.insertLink()
          break
        case "p":
          e.preventDefault()
          this.togglePreview()
          break
      }
    }
  }

  syncToHiddenInput() {
    if (this.hasInputTarget) {
      const content = this.getContent()
      this.inputTarget.value = content
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  getContent() {
    if (this.cm) {
      return this.cm.getValue()
    } else if (this.textarea) {
      return this.textarea.value
    }
    return ""
  }

  setContent(text) {
    if (this.cm) {
      this.cm.setValue(text)
    } else if (this.textarea) {
      this.textarea.value = text
    }
    this.syncToHiddenInput()
  }

  getSelection() {
    if (this.cm) {
      const from = this.cm.getCursor("from")
      const to = this.cm.getCursor("to")
      return {
        from: this.cm.indexFromPos(from),
        to: this.cm.indexFromPos(to),
        text: this.cm.getSelection()
      }
    } else if (this.textarea) {
      return {
        from: this.textarea.selectionStart,
        to: this.textarea.selectionEnd,
        text: this.textarea.value.substring(this.textarea.selectionStart, this.textarea.selectionEnd)
      }
    }
    return { from: 0, to: 0, text: "" }
  }

  insertText(text, selectFrom = null, selectTo = null) {
    if (this.cm) {
      const cursor = this.cm.getCursor()
      const selection = this.cm.getSelection()
      if (selection) {
        this.cm.replaceSelection(text)
      } else {
        this.cm.replaceRange(text, cursor)
      }

      // Handle selection after insert
      if (selectFrom !== null && selectTo !== null) {
        const newCursor = this.cm.getCursor()
        const startPos = this.cm.posFromIndex(this.cm.indexFromPos(newCursor) - text.length + selectFrom)
        const endPos = this.cm.posFromIndex(this.cm.indexFromPos(newCursor) - text.length + selectTo)
        this.cm.setSelection(startPos, endPos)
      }

      this.cm.focus()
    } else if (this.textarea) {
      this.insertTextAtCursor(text, selectFrom, selectTo)
    }
    this.syncToHiddenInput()
    if (this.previewVisible) {
      this.updatePreview()
    }
  }

  insertTextAtCursor(text, selectFrom = null, selectTo = null) {
    if (!this.textarea) return
    const { from, to } = this.getSelection()
    const before = this.textarea.value.substring(0, from)
    const after = this.textarea.value.substring(to)
    this.textarea.value = before + text + after

    if (selectFrom !== null && selectTo !== null) {
      this.textarea.selectionStart = from + selectFrom
      this.textarea.selectionEnd = from + selectTo
    } else {
      this.textarea.selectionStart = from + text.length
      this.textarea.selectionEnd = from + text.length
    }
    this.textarea.focus()
  }

  getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }

  // Toolbar actions
  insertBold() {
    const { text } = this.getSelection()
    if (text) {
      this.insertText(`**${text}**`)
    } else {
      this.insertText("**bold text**", 2, 11)
    }
  }

  insertItalic() {
    const { text } = this.getSelection()
    if (text) {
      this.insertText(`*${text}*`)
    } else {
      this.insertText("*italic text*", 1, 12)
    }
  }

  insertHeading() {
    const { text } = this.getSelection()
    if (text) {
      this.insertText(`## ${text}`)
    } else {
      this.insertText("## Heading", 3, 10)
    }
  }

  insertLink() {
    const { text } = this.getSelection()
    const url = prompt("Enter URL:", "https://")
    if (!url) return

    if (text) {
      this.insertText(`[${text}](${url})`)
    } else {
      const linkText = prompt("Enter link text:", "link")
      this.insertText(`[${linkText || "link"}](${url})`)
    }
  }

  insertImage() {
    const url = prompt("Enter image URL:", "/files/")
    if (!url) return

    const alt = prompt("Enter alt text:", "Image")
    this.insertText(`![${alt || "Image"}](${url})`)
  }

  insertQuote() {
    const { text } = this.getSelection()
    if (text) {
      const quoted = text.split("\n").map(line => `> ${line}`).join("\n")
      this.insertText(quoted)
    } else {
      this.insertText("> Quote", 2, 7)
    }
  }

  insertList() {
    const { text } = this.getSelection()
    if (text) {
      const listed = text.split("\n").map(line => `- ${line}`).join("\n")
      this.insertText(listed)
    } else {
      this.insertText("- Item 1\n- Item 2\n- Item 3", 2, 8)
    }
  }

  insertOrderedList() {
    const { text } = this.getSelection()
    if (text) {
      const listed = text.split("\n").map((line, i) => `${i + 1}. ${line}`).join("\n")
      this.insertText(listed)
    } else {
      this.insertText("1. Item 1\n2. Item 2\n3. Item 3", 3, 9)
    }
  }

  insertMore() {
    this.insertText("\n\n<!--more-->\n\n")
  }

  // Typo macro insertions
  insertTypoCode() {
    const { text } = this.getSelection()
    const lang = prompt("Enter programming language:", "ruby")
    if (!lang) return

    const code = text || "# Your code here"
    this.insertText(`<typo:code lang="${lang}">\n${code}\n</typo:code>`)
  }

  insertTypoAmazon() {
    const asin = prompt("Enter Amazon ASIN (10-character product ID):")
    if (!asin) return

    const title = prompt("Enter product title:") || ""
    const linkText = prompt("Enter link text:", title) || title

    this.insertText(`<typo:amazon asin="${asin}" title="${title}">${linkText}</typo:amazon>`)
  }

  insertTypoLightbox() {
    const src = prompt("Enter image URL:")
    if (!src) return

    const thumbsrc = prompt("Enter thumbnail URL (optional):", "")
    const caption = prompt("Enter caption (optional):", "")

    let attrs = `src="${src}"`
    if (thumbsrc) attrs += ` thumbsrc="${thumbsrc}"`
    if (caption) attrs += ` caption="${caption}"`

    this.insertText(`<typo:lightbox ${attrs}/>`)
  }

  // Preview functionality
  async togglePreview() {
    this.previewVisible = !this.previewVisible

    if (this.previewVisible) {
      await this.updatePreview()
      this.previewPane.style.display = "block"
      if (this.cm) {
        this.cm.getWrapperElement().style.display = "none"
      } else if (this.textarea) {
        this.textarea.style.display = "none"
      }
    } else {
      this.previewPane.style.display = "none"
      if (this.cm) {
        this.cm.getWrapperElement().style.display = "block"
        this.cm.refresh()
      } else if (this.textarea) {
        this.textarea.style.display = "block"
      }
    }

    // Update toggle button text
    const toggleBtn = this.element.querySelector('.preview-toggle')
    if (toggleBtn) {
      toggleBtn.textContent = this.previewVisible ? "Edit" : "Preview"
    }
  }

  async updatePreview() {
    if (!this.previewPane) return

    const content = this.getContent()

    try {
      const { marked } = await import("marked")
      marked.setOptions({ breaks: true, gfm: true })

      let html = marked.parse(content)
      html = this.processTypoMacrosForPreview(html)

      this.previewPane.innerHTML = html
    } catch (error) {
      console.error("Preview error:", error)
      this.previewPane.innerHTML = `<pre style="white-space: pre-wrap;">${this.escapeHtml(content)}</pre>`
    }
  }

  processTypoMacrosForPreview(html) {
    // Highlight typo:code blocks
    html = html.replace(/&lt;typo:code[^&]*&gt;([\s\S]*?)&lt;\/typo:code&gt;/g,
      '<div style="background: #f4f4f4; border: 1px solid #ddd; padding: 10px; border-radius: 4px; font-family: monospace;"><strong>[Code Block]</strong><pre>$1</pre></div>')

    // Highlight typo:amazon tags
    html = html.replace(/&lt;typo:amazon[^&]*&gt;([\s\S]*?)&lt;\/typo:amazon&gt;/g,
      '<span style="background: #fff3cd; padding: 2px 6px; border-radius: 3px;">📦 Amazon: $1</span>')

    // Highlight typo:lightbox tags
    html = html.replace(/&lt;typo:lightbox[^\/]*\/&gt;/g,
      '<span style="background: #d4edda; padding: 2px 6px; border-radius: 3px;">🖼️ Lightbox Image</span>')

    return html
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // Drag and drop handling
  handleDragOver(event) {
    if (event.dataTransfer && event.dataTransfer.types.includes("Files")) {
      event.preventDefault()
      event.dataTransfer.dropEffect = "copy"
      this.editorTarget.classList.add("drag-over")
    }
  }

  handleDragLeave(event) {
    this.editorTarget.classList.remove("drag-over")
  }

  handleDrop(event) {
    this.editorTarget.classList.remove("drag-over")

    const files = event.dataTransfer?.files
    if (!files || files.length === 0) return

    for (const file of files) {
      if (file.type.startsWith("image/")) {
        event.preventDefault()
        this.uploadImage(file)
        return
      }
    }
  }

  handlePaste(event) {
    const items = event.clipboardData?.items
    if (!items) return

    for (const item of items) {
      if (item.type.startsWith("image/")) {
        event.preventDefault()
        const file = item.getAsFile()
        if (file) {
          this.uploadImage(file)
        }
        return
      }
    }
  }

  // Image upload
  async uploadImage(file) {
    if (!this.hasUploadUrlValue) {
      console.error("No upload URL configured")
      return
    }

    const placeholder = `![Uploading ${file.name}...]()`
    this.insertText(placeholder)

    const formData = new FormData()
    formData.append("upload[filename]", file)

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": this.getCsrfToken() },
        body: formData
      })

      if (response.ok) {
        const data = await response.json()
        const alt = file.name.replace(/\.[^/.]+$/, "")
        const markdown = `![${alt}](${data.url})`

        const content = this.getContent()
        this.setContent(content.replace(placeholder, markdown))
      } else {
        console.error("Upload failed:", response.statusText)
        alert("Image upload failed. Please try again.")
      }
    } catch (error) {
      console.error("Upload error:", error)
      alert("Image upload failed. Please try again.")
    }
  }
};
