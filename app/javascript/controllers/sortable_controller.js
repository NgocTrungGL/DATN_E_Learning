import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = { url: String, param: String, handle: String };

  connect() {
    const handleSelector = this.hasHandleValue ? this.handleValue : ".drag-handle";

    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: handleSelector,
      filter: "a, button, input, textarea, select, [data-no-drag]",
      preventOnFilter: false,
      dataIdAttr: "data-id",
      onEnd: this.end.bind(this),
    });
  }

  async end() {
    const items = this.sortable.toArray();

    if (items.length === 0) return;

    const paramKey = this.hasParamValue ? this.paramValue : "course_module";
    const body = new URLSearchParams();
    items.forEach((id) => body.append(`${paramKey}[]`, id));

    const response = await fetch(this.urlValue, {
      method: "PATCH",
      credentials: "same-origin",
      headers: {
        Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body,
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Sortable update failed", {
        url: this.urlValue,
        status: response.status,
        payload: body.toString(),
        errorText,
      });
    }
  }
}
