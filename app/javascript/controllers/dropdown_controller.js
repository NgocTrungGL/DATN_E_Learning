import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["active"]

  toggle() {
    this.menuTarget.classList.toggle(this.activeClass)
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.remove(this.activeClass)
    }
  }

  connect() {
    this.clickOutsideHandler = this.hide.bind(this)
    document.addEventListener("click", this.clickOutsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }
}
