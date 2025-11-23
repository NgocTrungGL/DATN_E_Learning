class AddPriceToCoursesAndChangeEnrollmentStatus < ActiveRecord::Migration[7.0]
  def change
    # 1. Thêm giá tiền vào khóa học (Mặc định là 0 - Miễn phí)
    add_column :courses, :price, :decimal, precision: 10, scale: 2, default: 0.0

    # 2. Sửa cột status của Enrollment từ Boolean sang String để dùng Enum
    # (MySQL hỗ trợ change_column)
    change_column :enrollments, :status, :string, default: 'pending'
  end
end
