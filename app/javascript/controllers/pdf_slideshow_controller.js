import { Controller } from "@hotwired/stimulus"

// PDF Slideshow Controller
// Renders PDF pages as slides with keyboard navigation
export default class extends Controller {
  static targets = [
    "viewport",
    "canvas",
    "loading",
    "counter",
    "currentPage",
    "totalPages",
    "prevBtn",
    "nextBtn",
    "fullscreenIcon"
  ]

  static values = {
    src: String,
    autoplay: { type: Boolean, default: false },
    interval: { type: Number, default: 5000 },
    startPage: { type: Number, default: 1 }
  }

  connect() {
    this.currentPage = this.startPageValue
    this.totalPages = 0
    this.pdfDoc = null
    this.pageRendering = false
    this.pageNumPending = null
    this.scale = 1.5
    this.autoplayTimer = null

    // Bind keyboard handler
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)

    // Bind resize handler
    this.handleResize = this.debounce(this.handleResize.bind(this), 250)
    window.addEventListener('resize', this.handleResize)

    // Fullscreen change handler
    this.handleFullscreenChange = this.handleFullscreenChange.bind(this)
    document.addEventListener('fullscreenchange', this.handleFullscreenChange)

    // Load the PDF
    this.loadPdf()
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown)
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener('fullscreenchange', this.handleFullscreenChange)
    this.stopAutoplay()

    if (this.pdfDoc) {
      this.pdfDoc.destroy()
    }
  }

  async loadPdf() {
    if (!this.srcValue) {
      this.showError('No PDF source specified')
      return
    }

    this.showLoading(true)

    try {
      // Ensure PDF.js is loaded
      if (typeof pdfjsLib === 'undefined') {
        throw new Error('PDF.js library not loaded. Please refresh the page.')
      }

      this.pdfDoc = await pdfjsLib.getDocument(this.srcValue).promise
      this.totalPages = this.pdfDoc.numPages

      // Clamp start page to valid range
      if (this.currentPage < 1) this.currentPage = 1
      if (this.currentPage > this.totalPages) this.currentPage = this.totalPages

      this.updateCounter()
      this.updateNavigationState()

      // Render the initial page
      await this.renderPage(this.currentPage)

      this.showLoading(false)

      // Start autoplay if enabled
      if (this.autoplayValue) {
        this.startAutoplay()
      }

    } catch (error) {
      console.error('PDF loading error:', error)
      this.showError(`Failed to load PDF: ${error.message}`)
    }
  }

  async renderPage(pageNum) {
    if (!this.pdfDoc) return

    this.pageRendering = true

    try {
      const page = await this.pdfDoc.getPage(pageNum)

      const canvas = this.canvasTarget
      const ctx = canvas.getContext('2d')

      // Calculate scale to fit container
      const viewport = this.viewportTarget
      const containerWidth = viewport.clientWidth || 800
      const containerHeight = viewport.clientHeight || 500

      const originalViewport = page.getViewport({ scale: 1 })
      const scaleX = containerWidth / originalViewport.width
      const scaleY = containerHeight / originalViewport.height
      this.scale = Math.min(scaleX, scaleY) * 0.95 // 95% to add padding

      const scaledViewport = page.getViewport({ scale: this.scale })

      // Set canvas dimensions
      canvas.height = scaledViewport.height
      canvas.width = scaledViewport.width

      const renderContext = {
        canvasContext: ctx,
        viewport: scaledViewport
      }

      await page.render(renderContext).promise

      this.pageRendering = false

      // If another page was requested while rendering, render it now
      if (this.pageNumPending !== null) {
        const pending = this.pageNumPending
        this.pageNumPending = null
        this.renderPage(pending)
      }

    } catch (error) {
      console.error('Page render error:', error)
      this.pageRendering = false
    }
  }

  queueRenderPage(num) {
    if (this.pageRendering) {
      this.pageNumPending = num
    } else {
      this.renderPage(num)
    }
  }

  // Navigation Methods
  previousPage() {
    if (this.currentPage <= 1) return
    this.currentPage--
    this.updateCounter()
    this.updateNavigationState()
    this.queueRenderPage(this.currentPage)
    this.resetAutoplay()
  }

  nextPage() {
    if (this.currentPage >= this.totalPages) return
    this.currentPage++
    this.updateCounter()
    this.updateNavigationState()
    this.queueRenderPage(this.currentPage)
    this.resetAutoplay()
  }

  goToPage(pageNum) {
    if (pageNum < 1 || pageNum > this.totalPages) return
    this.currentPage = pageNum
    this.updateCounter()
    this.updateNavigationState()
    this.queueRenderPage(this.currentPage)
  }

  firstPage() {
    this.goToPage(1)
    this.resetAutoplay()
  }

  lastPage() {
    this.goToPage(this.totalPages)
    this.resetAutoplay()
  }

  // Keyboard Navigation
  handleKeydown(event) {
    // Only handle if this slideshow has focus or is in viewport
    const rect = this.element.getBoundingClientRect()
    const inViewport = rect.top < window.innerHeight && rect.bottom > 0

    // Check if we're in fullscreen for this element
    const isFullscreen = document.fullscreenElement === this.element

    // Skip if typing in an input or not relevant
    if (event.target.tagName === 'INPUT' ||
        event.target.tagName === 'TEXTAREA' ||
        event.target.isContentEditable) {
      return
    }

    // Only respond if in fullscreen or element is in viewport and visible
    if (!isFullscreen && !inViewport) return

    switch (event.key) {
      case 'ArrowLeft':
      case 'ArrowUp':
        event.preventDefault()
        this.previousPage()
        break
      case 'ArrowRight':
      case 'ArrowDown':
      case ' ':
        event.preventDefault()
        this.nextPage()
        break
      case 'Home':
        event.preventDefault()
        this.firstPage()
        break
      case 'End':
        event.preventDefault()
        this.lastPage()
        break
      case 'f':
      case 'F':
        if (!event.ctrlKey && !event.metaKey) {
          event.preventDefault()
          this.toggleFullscreen()
        }
        break
      case 'Escape':
        if (document.fullscreenElement === this.element) {
          document.exitFullscreen()
        }
        break
    }
  }

  // Fullscreen
  toggleFullscreen() {
    if (!document.fullscreenElement) {
      this.element.requestFullscreen().catch(err => {
        console.error('Fullscreen error:', err)
      })
    } else {
      document.exitFullscreen()
    }
  }

  handleFullscreenChange() {
    const isFullscreen = document.fullscreenElement === this.element
    this.updateFullscreenIcon(isFullscreen)

    // Re-render to fit new dimensions
    setTimeout(() => {
      this.handleResize()
    }, 100)
  }

  updateFullscreenIcon(isFullscreen) {
    if (!this.hasFullscreenIconTarget) return

    if (isFullscreen) {
      // Exit fullscreen icon
      this.fullscreenIconTarget.innerHTML =
        '<path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/>'
    } else {
      // Enter fullscreen icon
      this.fullscreenIconTarget.innerHTML =
        '<path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/>'
    }
  }

  // Autoplay
  startAutoplay() {
    if (this.autoplayTimer) return

    this.autoplayTimer = setInterval(() => {
      if (this.currentPage < this.totalPages) {
        this.nextPage()
      } else {
        this.stopAutoplay()
      }
    }, this.intervalValue)
  }

  stopAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer)
      this.autoplayTimer = null
    }
  }

  resetAutoplay() {
    if (this.autoplayValue) {
      this.stopAutoplay()
      this.startAutoplay()
    }
  }

  // UI Updates
  updateCounter() {
    if (this.hasCurrentPageTarget) {
      this.currentPageTarget.textContent = this.currentPage
    }
    if (this.hasTotalPagesTarget) {
      this.totalPagesTarget.textContent = this.totalPages
    }
  }

  updateNavigationState() {
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentPage <= 1
    }
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = this.currentPage >= this.totalPages
    }
  }

  showLoading(show) {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = show ? 'flex' : 'none'
    }
    if (this.hasCanvasTarget) {
      this.canvasTarget.style.display = show ? 'none' : 'block'
    }
  }

  showError(message) {
    this.showLoading(false)
    if (this.hasViewportTarget) {
      this.viewportTarget.innerHTML = `
        <div class="pdf-slideshow-error-display">
          <svg viewBox="0 0 24 24" width="48" height="48">
            <path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
          </svg>
          <p>${this.escapeHtml(message)}</p>
        </div>
      `
    }
  }

  // Resize handling
  handleResize() {
    if (this.pdfDoc && this.currentPage) {
      this.queueRenderPage(this.currentPage)
    }
  }

  // Utilities
  debounce(func, wait) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
