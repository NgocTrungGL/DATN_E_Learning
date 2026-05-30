import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = {
    url: String,
    handle: String,
    nested: Boolean,
  };

  connect() {
    if (this.hasNestedValue && this.nestedValue) {
      this.initNestedSortable();
    } else {
      this.initSimpleSortable();
    }
  }

  initSimpleSortable() {
    const options = {
      animation: 150,
      dataIdAttr: "data-id",
      filter: "a, button, input, textarea, select, [data-no-drag]",
      onEnd: () => this.saveOrder(),
    };
    if (this.hasHandleValue) options.handle = this.handleValue;
    Sortable.create(this.element, options);
  }

  initNestedSortable() {
    // Init modules sortable on this element
    const moduleOptions = {
      animation: 150,
      dataIdAttr: "data-id",
      handle: ".module-drag-handle",
      filter: "a, button, input, textarea, select, [data-no-drag]",
      onEnd: () => this.saveModuleOrder(),
    };
    Sortable.create(this.element, moduleOptions);

    // Init lesson sortable for each lessons container
    this.initLessonSortables();

    // Re-init on turbo:frame-load (Turbo navigation)
    this.element.addEventListener("turbo:frame-load", () => this.initLessonSortables());
  }

  initLessonSortables() {
    this.element.querySelectorAll(".lessons-tree").forEach((container) => {
      if (container.dataset.sortableInitialized) return;
      container.dataset.sortableInitialized = "true";

      Sortable.create(container, {
        group: { name: "lessons", pull: true, put: true },
        animation: 150,
        dataIdAttr: "data-id",
        handle: ".lesson-drag-handle",
        filter: "a, button, input, textarea, select, [data-no-drag]",
        onEnd: () => this.saveLessonOrder(),
      });
    });
  }

  async saveModuleOrder() {
    const items = Array.from(this.element.querySelectorAll(".module-block"))
      .map((el) => el.dataset.moduleId)
      .filter(Boolean);

    if (!items.length) return;

    const body = new URLSearchParams();
    items.forEach((id) => body.append("module_order[]", id));
    await this.send(this.urlValue, body);
  }

  async saveLessonOrder() {
    const courseId = this.element.dataset.sortableContainer?.replace("course-", "");
    if (!courseId) return;

    const lessonOrder = [];
    this.element.querySelectorAll(".module-block").forEach((mod) => {
      const moduleId = mod.dataset.moduleId;
      mod.querySelectorAll(".lesson-item").forEach((lesson) => {
        const id = lesson.dataset.lessonId;
        if (!id) return;
        lessonOrder.push({ id, module_id: moduleId });
      });
    });

    const body = new URLSearchParams();
    lessonOrder.forEach((l) => body.append("lesson_order[]", JSON.stringify(l)));
    await this.send(`/instructor/courses/${courseId}/sort_lessons`, body);
  }

  async send(url, body) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    if (!token || !url) return;

    const response = await fetch(url, {
      method: "PATCH",
      credentials: "same-origin",
      headers: {
        Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": token,
      },
      body,
    });

    if (!response.ok) {
      console.error("Sortable update failed", { url, status: response.status });
    }
  }
}
