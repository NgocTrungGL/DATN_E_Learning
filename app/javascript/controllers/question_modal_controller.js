import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  open() {
    this.element.classList.add("is-open");
    document.body.style.overflow = "hidden";
    requestAnimationFrame(() => {
      this.element.querySelector("textarea")?.focus();
    });
  }

  close() {
    this.element.classList.remove("is-open");
    document.body.style.overflow = "";
  }

  reset() {
    this.close();
    const form = this.element.querySelector("textarea");
    if (form) form.value = "";
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.element.classList.contains("is-open")) {
      this.close();
    }
  }

  connect() {
    document.addEventListener("keydown", this.closeOnEscape.bind(this));
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape.bind(this));
  }
}
