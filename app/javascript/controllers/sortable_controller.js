import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = { url: String };

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: ".drag-handle",
      onEnd: this.end.bind(this),
    });
  }

  end(event) {
    const id = event.item.dataset.id;
    const data = new FormData();

    const items = this.sortable.toArray();

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: JSON.stringify({ course_module: items }),
    });
  }
}
