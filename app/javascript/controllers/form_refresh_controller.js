import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["courseSelect", "lessonSelect"];

  connect() {
    console.log("Form Refresh Controller Connected");
  }

  updateLessons() {
    const courseId = this.courseSelectTarget.value;
    const lessonSelect = this.lessonSelectTarget;

    lessonSelect.innerHTML =
      '<option value="">--- Chọn Bài học (Hoặc để trống nếu là Quiz lớn) ---</option>';

    if (!courseId) return;

    fetch(`/admin/courses/${courseId}/lessons`)
      .then((response) => response.json())
      .then((lessons) => {
        lessons.forEach((lesson) => {
          const option = document.createElement("option");
          option.value = lesson.id;
          option.text = lesson.title;
          lessonSelect.appendChild(option);
        });
      })
      .catch((error) => console.error("Error loading lessons:", error));
  }
}
