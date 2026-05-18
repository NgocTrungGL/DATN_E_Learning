import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "panelTitle", "panelContent", "infoPanel"]

  connect() {
    // No auto-open on load — panel is idle until user clicks Reply
  }

  // Called when user clicks the Reply button on a message
  openThread(event) {
    const threadUrl = event.currentTarget.dataset.threadUrl
    if (!threadUrl) return

    // Open the panel
    this.containerTarget.classList.add("lumina--panel-open")

    // Update panel header
    if (this.hasPanelTitleTarget) {
      this.panelTitleTarget.innerText = "Thread"
    }

    // Navigate the Turbo Frame inside the panel to the thread URL
    const frame = this.panelContentTarget.querySelector("turbo-frame#thread-panel")
    if (frame) {
      frame.src = threadUrl
    }
  }

  togglePanel() {
    this.containerTarget.classList.toggle("lumina--panel-open")
  }

  closePanel() {
    this.containerTarget.classList.remove("lumina--panel-open")
  }

  startResize(event) {
    event.preventDefault()
    this.isResizing = true

    // Bind mouse events
    this.boundResize = this.resize.bind(this)
    this.boundStopResize = this.stopResize.bind(this)

    document.addEventListener('mousemove', this.boundResize)
    document.addEventListener('mouseup', this.boundStopResize)

    // Prevent text selection and show resize cursor everywhere while dragging
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
    
    // Disable grid transition during resize for immediate feedback without lag
    this.containerTarget.style.transition = 'none'
  }

  resize(event) {
    if (!this.isResizing) return

    // The panel is on the right, so its width is the distance from the mouse to the right edge.
    const newWidth = window.innerWidth - event.clientX

    // Clamp width between 300px and 800px, but no more than 60% of the screen width
    const maxWidth = Math.min(800, window.innerWidth * 0.6)
    const clampedWidth = Math.max(300, Math.min(newWidth, maxWidth))

    this.containerTarget.style.setProperty('--thread-panel-width', `${clampedWidth}px`)
  }

  stopResize(event) {
    this.isResizing = false
    document.removeEventListener('mousemove', this.boundResize)
    document.removeEventListener('mouseup', this.boundStopResize)

    // Reset styles
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
    this.containerTarget.style.transition = ''
  }
}
