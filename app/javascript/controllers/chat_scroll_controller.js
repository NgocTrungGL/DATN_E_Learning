import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  // Observe the chat-messages container for new additions
  observeNewMessages() {
    const targetNode = document.getElementById("chat-messages")
    if (!targetNode) return

    const config = { childList: true }
    const callback = (mutationsList) => {
      for (const mutation of mutationsList) {
        if (mutation.type === "childList") {
          this.scrollToBottom()
        }
      }
    }

    this.observer = new MutationObserver(callback)
    this.observer.observe(targetNode, config)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}
