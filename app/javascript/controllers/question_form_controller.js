import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // Khai báo các targets để thao tác với DOM
  static targets = [
    "typeSelect",
    "optionsList",
    "addButtonContainer",
    "template",
  ];

  connect() {
    // Gọi hàm này ngay khi load trang để setup trạng thái ban đầu
    this.toggleType();
  }

  // Hàm này chạy mỗi khi dropdown "Loại câu hỏi" thay đổi
  toggleType() {
    const type = this.typeSelectTarget.value;

    // Tìm tất cả các ô input và nút xóa trong danh sách đáp án
    const inputs = this.optionsListTarget.querySelectorAll(
      "input.option-selector"
    );
    const deleteButtons = this.optionsListTarget.querySelectorAll(
      "button[data-action='question-form#removeAssociation']"
    );

    if (type === "single") {
      // === TRƯỜNG HỢP 1: SINGLE CHOICE ===

      // 1. QUAN TRỌNG: Ẩn nút "Thêm lựa chọn" đi
      if (this.hasAddButtonContainerTarget) {
        this.addButtonContainerTarget.style.display = "none";
      }

      // 2. Chuyển input sang dạng Radio & bỏ chọn các cái khác (chỉ giữ 1 cái)
      inputs.forEach((input) => {
        input.type = "radio";
      });
      this.ensureSingleSelection(inputs);

      // 3. Ẩn các nút xóa (để giữ cố định 4 đáp án)
      deleteButtons.forEach((btn) => (btn.style.display = "none"));
    } else {
      // === TRƯỜNG HỢP 2: MULTIPLE CHOICE ===

      // 1. Hiện nút "Thêm lựa chọn" lên
      if (this.hasAddButtonContainerTarget) {
        this.addButtonContainerTarget.style.display = "block";
      }

      // 2. Chuyển input về dạng Checkbox
      inputs.forEach((input) => {
        input.type = "checkbox";
      });

      // 3. Hiện lại các nút xóa
      deleteButtons.forEach((btn) => (btn.style.display = "inline-block"));
    }
  }

  // Hàm xử lý logic khi click vào radio button (Single)
  handleCheck(event) {
    const type = this.typeSelectTarget.value;
    if (type === "single") {
      const currentInput = event.target;

      // Nếu user vừa check vào input này -> Uncheck tất cả cái còn lại
      if (currentInput.checked) {
        const allInputs = this.optionsListTarget.querySelectorAll(
          "input.option-selector"
        );
        allInputs.forEach((input) => {
          if (input !== currentInput) {
            input.checked = false;
          }
        });
      }
    }
  }

  // Hàm phụ trợ: Đảm bảo khi chuyển từ Multi -> Single thì chỉ có tối đa 1 cái được chọn
  ensureSingleSelection(inputs) {
    let checkedFound = false;
    inputs.forEach((input) => {
      if (input.checked) {
        if (checkedFound) {
          input.checked = false; // Đã có cái chọn trước đó rồi thì bỏ chọn cái này
        } else {
          checkedFound = true;
        }
      }
    });
  }

  // Thêm dòng record mới
  addAssociation(event) {
    event.preventDefault();
    // Lấy nội dung template và thay thế ID tạm thời
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime()
    );

    // Chèn vào cuối danh sách
    this.optionsListTarget.insertAdjacentHTML("beforeend", content);

    // Update lại trạng thái (checkbox/radio) cho dòng mới vừa thêm
    this.toggleType();
  }

  // Xóa dòng record
  removeAssociation(event) {
    event.preventDefault();
    const wrapper = event.target.closest(".nested-form-wrapper");

    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove(); // Xóa khỏi DOM nếu chưa lưu DB
    } else {
      wrapper.querySelector("input[name*='_destroy']").value = 1; // Đánh dấu xóa
      wrapper.style.display = "none"; // Ẩn đi
    }
  }
}
