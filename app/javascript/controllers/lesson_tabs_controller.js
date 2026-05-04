import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    // Initial state check - if any tab is marked active in HTML, ensure its panel is shown
    this.showActiveTab()
  }

  switch(event) {
    const clickedTrigger = event.currentTarget
    const targetName = clickedTrigger.dataset.target

    // 1. Update trigger buttons
    this.triggerTargets.forEach(trigger => {
      const isActive = trigger === clickedTrigger
      trigger.classList.toggle("lesson-tabs__nav-item--active", isActive)
      trigger.setAttribute("aria-selected", isActive ? "true" : "false")
    })

    // 2. Update panels
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.panel === targetName
      panel.classList.toggle("lesson-tabs__panel--active", isActive)
      panel.hidden = !isActive
    })
  }

  showActiveTab() {
    const activeTrigger = this.triggerTargets.find(t => t.classList.contains("lesson-tabs__nav-item--active"))
    if (activeTrigger) {
      const targetName = activeTrigger.dataset.target
      this.panelTargets.forEach(panel => {
        const isActive = panel.dataset.panel === targetName
        panel.classList.toggle("lesson-tabs__panel--active", isActive)
        panel.hidden = !isActive
      })
    }
  }
}
