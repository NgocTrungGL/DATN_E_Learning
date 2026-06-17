import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parentSelect", "subSelect", "categoryInput"]
  static values = {
    allSubcategoriesLabel: String
  }

  connect() {
    this.subSelectWrapper = this.subSelectTarget.closest(".crs-search-form__select-wrap")
    this.syncCategoryInput()
  }

  async changeParent() {
    const parentId = this.parentSelectTarget.value
    const selectedOption = this.parentSelectTarget.selectedOptions[0]
    const hasChildren = selectedOption && selectedOption.dataset.hasChildren === "true"

    this.resetSubcategories()
    this.categoryInputTarget.value = parentId

    if (!parentId || !hasChildren) {
      this.hideSubcategories()
      return
    }

    try {
      const response = await fetch(`/api/v1/categories/${parentId}/subcategories`, {
        headers: { Accept: "application/json" }
      })

      if (!response.ok) {
        this.hideSubcategories()
        return
      }

      const payload = await response.json()
      this.renderSubcategories(payload.data || [])
    } catch (_error) {
      this.hideSubcategories()
    }
  }

  changeSub() {
    this.syncCategoryInput()
  }

  syncCategoryInput() {
    this.categoryInputTarget.value = this.subSelectTarget.value || this.parentSelectTarget.value
  }

  resetSubcategories() {
    this.subSelectTarget.innerHTML = ""
    const option = document.createElement("option")
    option.value = ""
    option.textContent = this.allSubcategoriesLabelValue
    this.subSelectTarget.appendChild(option)
    this.subSelectTarget.value = ""
  }

  renderSubcategories(categories) {
    if (categories.length === 0) {
      this.hideSubcategories()
      return
    }

    categories.forEach((category) => {
      const option = document.createElement("option")
      option.value = category.id
      option.textContent = category.name
      this.subSelectTarget.appendChild(option)
    })

    this.showSubcategories()
  }

  hideSubcategories() {
    this.subSelectWrapper.classList.add("is-hidden")
  }

  showSubcategories() {
    this.subSelectWrapper.classList.remove("is-hidden")
  }
}
