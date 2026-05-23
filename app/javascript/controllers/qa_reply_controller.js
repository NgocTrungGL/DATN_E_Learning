import { Controller } from "@hotwired/stimulus"

// Toggle the reply form under a question card
export default class extends Controller {
  static targets = ["toggle", "form"]

  toggle(event) {
    const btn       = event.currentTarget
    const commentId = btn.dataset.commentId
    const formId    = `replyForm${commentId}`
    const form      = document.getElementById(formId)
    if (!form) return

    const isHidden  = form.hasAttribute("hidden")

    // Close all other open reply forms
    document.querySelectorAll("[data-qa-reply-target='form']").forEach(el => {
      if (el !== form) {
        el.setAttribute("hidden", "")
        const tb = document.querySelector(`[data-action*='qa-reply#toggle'][data-comment-id='${el.id.replace('replyForm', '')}']`)
        if (tb) {
          tb.classList.remove("is-open")
          tb.setAttribute("aria-expanded", "false")
        }
      }
    })

    if (isHidden) {
      form.removeAttribute("hidden")
      btn.classList.add("is-open")
      btn.setAttribute("aria-expanded", "true")
      const ta = form.querySelector("textarea")
      if (ta) ta.focus()
    } else {
      form.setAttribute("hidden", "")
      btn.classList.remove("is-open")
      btn.setAttribute("aria-expanded", "false")
    }
  }

  cancel(event) {
    const commentId = event.currentTarget.dataset.commentId
    const formId    = `replyForm${commentId}`
    const form      = document.getElementById(formId)
    const toggleBtn = document.querySelector(`[data-action*='qa-reply#toggle'][data-comment-id='${commentId}']`)

    if (form) {
      form.setAttribute("hidden", "")
      const ta = form.querySelector("textarea")
      if (ta) ta.value = ""
    }
    if (toggleBtn) {
      toggleBtn.classList.remove("is-open")
      toggleBtn.setAttribute("aria-expanded", "false")
    }
  }
}
