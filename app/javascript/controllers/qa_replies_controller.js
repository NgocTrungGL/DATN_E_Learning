import { Controller } from "@hotwired/stimulus"

// Toggle the replies list under a question card
export default class extends Controller {
  static targets = ["toggle", "list"]

  toggle(event) {
    const btn       = event.currentTarget
    const commentId = btn.dataset.commentId
    const listId    = `repliesList${commentId}`
    const list      = document.getElementById(listId)
    if (!list) return

    const isHidden  = list.hasAttribute("hidden")

    if (isHidden) {
      list.removeAttribute("hidden")
      btn.classList.add("is-open")
      btn.setAttribute("aria-expanded", "true")
    } else {
      list.setAttribute("hidden", "")
      btn.classList.remove("is-open")
      btn.setAttribute("aria-expanded", "false")
    }
  }
}
