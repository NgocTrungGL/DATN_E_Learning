import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabs"]

  switch(event) {
    const { tab } = event.currentTarget.dataset
    
    // Smooth indicator transition
    this.tabsTarget.classList.toggle("is-register", tab === "register")

    // Dynamic active tab switching
    this.element.querySelectorAll(".tab-btn").forEach(btn => {
      btn.classList.toggle("active", btn.dataset.tab === tab)
    })
  }
}
