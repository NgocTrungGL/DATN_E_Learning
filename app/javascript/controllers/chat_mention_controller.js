import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    courseId: Number
  }

  connect() {
    this.textarea = this.element.querySelector("textarea")
    if (!this.textarea) return

    // State management
    this.dropdown = null
    this.results = []
    this.activeIndex = 0
    this.mentionQuery = ""
    this.mentionStartIndex = -1
    this.dropdownOpen = false
    this.latestQuery = ""
    this.fetchTimeout = null

    // Bind event handlers
    this.inputHandler = this.handleInput.bind(this)
    this.keydownHandler = this.handleKeydown.bind(this)
    this.clickHandler = this.handleClick.bind(this)
    this.outsideClickHandler = this.handleOutsideClick.bind(this)

    // Attach listeners
    this.textarea.addEventListener("input", this.inputHandler)
    // Attach keydown to the parent element in the capture phase to intercept before Stimulus actions
    this.element.addEventListener("keydown", this.keydownHandler, true)
    this.textarea.addEventListener("click", this.clickHandler)
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    if (this.textarea) {
      this.textarea.removeEventListener("input", this.inputHandler)
      this.textarea.removeEventListener("click", this.clickHandler)
    }
    this.element.removeEventListener("keydown", this.keydownHandler, true)
    document.removeEventListener("click", this.outsideClickHandler)
    this.removeDropdown()
  }

  handleInput(event) {
    const cursor = this.textarea.selectionStart
    const textBeforeCursor = this.textarea.value.substring(0, cursor)
    
    // Match '@' followed by word characters up to the cursor
    const match = textBeforeCursor.match(/@([a-zA-Z0-9_\sÀ-ỹ]*)$/)
    
    if (match) {
      const fullMatch = match[0]
      const query = match[1]
      
      // If there's a space after '@' but no name yet, or space within mention
      // Slack allows searching with spaces, but let's restrict to not breaking
      // if they type a newline or space followed by non-letters
      if (query.includes("\n")) {
        this.hideDropdown()
        return
      }

      this.mentionQuery = query
      this.mentionStartIndex = cursor - fullMatch.length
      
      clearTimeout(this.fetchTimeout)
      this.fetchTimeout = setTimeout(() => {
        this.fetchResults(query)
      }, 150)
    } else {
      this.hideDropdown()
    }
  }

  handleKeydown(event) {
    if (!this.dropdownOpen || !this.dropdown) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        event.stopPropagation()
        this.navigate(1)
        break
      case "ArrowUp":
        event.preventDefault()
        event.stopPropagation()
        this.navigate(-1)
        break
      case "Enter":
      case "Tab":
        event.preventDefault()
        event.stopPropagation()
        this.selectActive()
        break
      case "Escape":
        event.preventDefault()
        event.stopPropagation()
        this.hideDropdown()
        break
    }
  }

  handleClick() {
    this.handleInput()
  }

  handleOutsideClick(event) {
    if (this.dropdownOpen && !this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  async fetchResults(query) {
    this.latestQuery = query

    try {
      const response = await fetch(`/courses/${this.courseIdValue}/chat/mentions?query=${encodeURIComponent(query)}`)
      if (!response.ok) throw new Error("Network error")
      
      const results = await response.json()
      
      // Ignore outdated responses
      if (this.latestQuery !== query) return

      this.results = results
      
      if (this.results.length > 0) {
        this.showDropdown()
        this.renderDropdown()
      } else {
        this.hideDropdown()
      }
    } catch (error) {
      console.error("Error fetching mention results:", error)
      if (this.latestQuery === query) {
        this.hideDropdown()
      }
    }
  }

  showDropdown() {
    if (this.dropdownOpen) return

    this.dropdown = document.createElement("div")
    this.dropdown.className = "lumina__mention-dropdown"
    
    // Position absolute above the input container
    this.element.appendChild(this.dropdown)
    this.dropdownOpen = true
    this.activeIndex = 0
  }

  hideDropdown() {
    this.removeDropdown()
    this.dropdownOpen = false
    this.results = []
    this.activeIndex = 0
  }

  removeDropdown() {
    if (this.dropdown && this.dropdown.parentNode) {
      this.dropdown.parentNode.removeChild(this.dropdown)
    }
    this.dropdown = null
  }

  renderDropdown() {
    if (!this.dropdown) return

    this.dropdown.innerHTML = ""
    
    this.results.forEach((item, index) => {
      const itemEl = document.createElement("div")
      const isActive = index === this.activeIndex
      
      itemEl.className = `mention-item ${isActive ? "mention-item--active" : ""}`
      itemEl.dataset.index = index
      
      itemEl.innerHTML = `
        <div class="mention-item__avatar" style="background: ${item.avatar_bg};">
          ${item.avatar_initial}
        </div>
        <div class="mention-item__info">
          <div class="mention-item__name">${item.name}</div>
          <div class="mention-item__email">${item.email}</div>
        </div>
        ${item.is_instructor ? '<span class="mention-item__badge">Instructor</span>' : ""}
      `
      
      // Mouse select handlers
      itemEl.addEventListener("click", (e) => {
        e.preventDefault()
        e.stopPropagation()
        this.selectItem(item)
      })

      itemEl.addEventListener("mouseenter", () => {
        this.setActiveIndex(index)
      })

      this.dropdown.appendChild(itemEl)
    })
  }

  navigate(direction) {
    const total = this.results.length
    if (total === 0) return

    this.activeIndex = (this.activeIndex + direction + total) % total
    this.renderDropdown()
    
    // Scroll active item into view if needed
    const activeItem = this.dropdown.querySelector(".mention-item--active")
    if (activeItem) {
      activeItem.scrollIntoView({ block: "nearest" })
    }
  }

  setActiveIndex(index) {
    this.activeIndex = index
    const items = this.dropdown.querySelectorAll(".mention-item")
    items.forEach((item, idx) => {
      if (idx === index) {
        item.classList.add("mention-item--active")
      } else {
        item.classList.remove("mention-item--active")
      }
    })
  }

  selectActive() {
    if (this.results.length === 0) return
    const activeItem = this.results[this.activeIndex]
    this.selectItem(activeItem)
  }

  selectItem(item) {
    const cursor = this.textarea.selectionStart
    const value = this.textarea.value
    
    const beforeMention = value.substring(0, this.mentionStartIndex)
    const afterMention = value.substring(cursor)
    
    // Format mention string: e.g. @Hoàng Điệp
    const mentionString = `@${item.name} `
    
    this.textarea.value = beforeMention + mentionString + afterMention
    
    // Set new cursor position after the trailing space
    const newCursorPos = this.mentionStartIndex + mentionString.length
    this.textarea.setSelectionRange(newCursorPos, newCursorPos)
    
    this.hideDropdown()
    this.textarea.focus()

    // Trigger input event to let chat-form resize the textarea automatically
    this.textarea.dispatchEvent(new Event("input"))
  }
}
