import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions"]
  static values = {
    url: String,
    selectedId: Number
  }

  connect() {
    this.timeout = null
    this.abortController = null
  }

  disconnect() {
    clearTimeout(this.timeout)
    if (this.abortController) this.abortController.abort()
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.fetchSuggestions(), 180)
  }

  async fetchSuggestions() {
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.clearSuggestions()
      return
    }

    if (this.abortController) this.abortController.abort()
    this.abortController = new AbortController()

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("query", query)

      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) return

      const employees = await response.json()
      this.renderSuggestions(employees)
    } catch (error) {
      if (error.name !== "AbortError") this.clearSuggestions()
    }
  }

  renderSuggestions(employees) {
    if (employees.length === 0) {
      this.suggestionsTarget.innerHTML = '<div class="biz-report-suggestions__empty">No employees found.</div>'
      return
    }

    this.suggestionsTarget.innerHTML = employees.map((employee) => this.suggestionTemplate(employee)).join("")
  }

  suggestionTemplate(employee) {
    const activeClass = employee.id === this.selectedIdValue ? " is-active" : ""

    return `
      <a href="${employee.url}" class="biz-report-suggestion${activeClass}" data-action="click->employee-search#clearSuggestions">
        <span class="biz-report-suggestion__avatar">${this.escapeHtml(employee.initial)}</span>
        <span class="biz-report-suggestion__body">
          <strong>${this.escapeHtml(employee.name)}</strong>
          <small>${this.escapeHtml(employee.email)}</small>
        </span>
        <i class="bi bi-arrow-right"></i>
      </a>
    `
  }

  clearSuggestions() {
    this.suggestionsTarget.innerHTML = ""
  }

  escapeHtml(value) {
    return String(value || "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;")
  }
}
