import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "panelTitle", "panelContent"]

  connect() {
    // Check if there is a thread ID in the URL to open it immediately
    const urlParams = new URLSearchParams(window.location.search)
    const openThreadId = urlParams.get('thread_id')
    if (openThreadId) {
      this.openThreadById(openThreadId)
    }
  }

  togglePanel() {
    this.containerTarget.classList.toggle("lumina--panel-open")
  }

  openThread(event) {
    const threadId = event.currentTarget.dataset.threadId
    const threadTitle = event.currentTarget.dataset.threadTitle
    
    this.panelTitleTarget.innerText = `Thảo luận: ${threadTitle}`
    this.containerTarget.classList.add("lumina--panel-open")
    
    // Simulate loading thread content
    this.panelContentTarget.innerHTML = `<div style="text-align:center; padding: 3rem 1rem;">
      <div class="spinner-border text-primary" role="status"></div>
      <p style="margin-top: 1rem; color: var(--lumina-text-muted);">Đang tải phản hồi...</p>
    </div>`

    // Fetch the thread content via Turbo Frame or AJAX
    // For now, we redirect or use a simple frame if available
    fetch(window.location.pathname.replace('/chat', `/discussions/${threadId}`))
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const replies = doc.querySelector('.disc-replies')
        if (replies) {
          this.panelContentTarget.innerHTML = replies.innerHTML
        } else {
          this.panelContentTarget.innerHTML = '<p style="text-align:center; padding: 2rem;">Không tìm thấy phản hồi.</p>'
        }
      })
  }

  closePanel() {
    this.containerTarget.classList.remove("lumina--panel-open")
  }
}
