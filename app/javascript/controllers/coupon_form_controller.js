import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["targetType", "courseField"]

  connect() {
    this.toggleCourseField()
  }

  toggleCourseField() {
    const isCourseSpecific = this.targetTypeTarget.value === "specific_course"
    this.courseFieldTarget.classList.toggle("is-hidden", !isCourseSpecific)
  }
}
