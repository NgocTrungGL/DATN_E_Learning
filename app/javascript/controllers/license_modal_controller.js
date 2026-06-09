import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "assignPanel", "employeesPanel"]

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.close()
  }

  open(event) {
    const panel = event.params.panel || "assign"

    this.showPanel(panel)
    this.modalTarget.classList.add("is-open")
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("biz-license-modal-open")
    document.addEventListener("keydown", this.handleKeydown)
  }

  close() {
    if (!this.hasModalTarget) return

    this.modalTarget.classList.remove("is-open")
    this.modalTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("biz-license-modal-open")
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  showPanel(panel) {
    const showEmployees = panel === "employees"

    this.assignPanelTarget.classList.toggle("is-hidden", showEmployees)
    this.employeesPanelTarget.classList.toggle("is-hidden", !showEmployees)
  }
}
