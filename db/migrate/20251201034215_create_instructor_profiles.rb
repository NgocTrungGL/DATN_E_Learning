class CreateInstructorProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :instructor_profiles do |t|
      # Liên kết với bảng users
      t.references :user, null: false, foreign_key: true, unique: true

      # Thông tin chuyên môn
      t.text :bio_detailed      #
      t.string :linkedin_url
      t.string :cv_url          # Link Google Drive/Dropbox CV
      t.string :website_url

      # Thông tin thanh toán
      t.string :bank_name
      t.string :bank_account_number
      t.string :bank_account_name

      # pending: Vừa đăng ký, chờ Admin
      # approved: Đã trở thành Giảng viên
      # rejected: Bị từ chối
      t.string :status, default: 'pending', null: false

      t.text :admin_note

      t.timestamps
    end
  end
end
