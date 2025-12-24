import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "lessonSelect",
    "manualSection",
    "randomSection",
    "totalInput",
    "countInput",
    "totalHint",
  ];

  connect() {
    this.toggleMode();
    // Nếu đang edit bài random, tính lại tổng
    if (this.isRandomMode()) {
      this.updateTotal();
    }
  }

  // Kiểm tra xem có đang ở chế độ Random không (Lesson rỗng = Random)
  isRandomMode() {
    return this.lessonSelectTarget.value === "";
  }

  toggleMode() {
    if (this.isRandomMode()) {
      // --- RANDOM MODE ---
      this.randomSectionTarget.classList.remove("d-none");
      this.manualSectionTarget.classList.add("d-none");

      // Khóa ô Total, bắt buộc tính toán tự động từ 3 ô dưới
      this.totalInputTarget.setAttribute("readonly", true);
      this.totalInputTarget.classList.add("bg-light");
      this.totalHintTarget.innerText =
        "Chế độ Random: Tổng số câu được tính tự động từ cấu hình bên dưới.";

      this.updateTotal();
    } else {
      // --- MANUAL MODE ---
      this.randomSectionTarget.classList.add("d-none");
      this.manualSectionTarget.classList.remove("d-none");

      // Mở khóa ô Total cho người dùng tự nhập
      this.totalInputTarget.removeAttribute("readonly");
      this.totalInputTarget.classList.remove("bg-light");
      this.totalHintTarget.innerText =
        "Chế độ Thủ công: Hãy nhập số lượng câu hỏi bạn dự định thêm.";
    }
  }

  // Tính tổng 3 ô input (Dễ + Vừa + Khó)
  updateTotal() {
    if (!this.isRandomMode()) return;

    let sum = 0;
    this.countInputTargets.forEach((input) => {
      sum += parseInt(input.value) || 0;
    });
    this.totalInputTarget.value = sum;
  }
}
