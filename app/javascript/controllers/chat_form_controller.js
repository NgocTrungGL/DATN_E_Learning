import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.resizeInput()
  }

  reset() {
    this.element.reset()
    this.resizeInput()
    // Dispatch input event so other controllers (like chat-mention) can reset their state
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  submitOnEnter(event) {
    if (event.defaultPrevented) return
    
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  resizeInput() {
    this.inputTarget.style.height = "auto"
    if (!this.inputTarget.value || this.inputTarget.value.trim() === "") {
      this.inputTarget.style.height = "24px"
    } else {
      this.inputTarget.style.height = `${this.inputTarget.scrollHeight}px`
    }
  }
}
