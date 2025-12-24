class CreateCartItems < ActiveRecord::Migration[7.0]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
    # Đảm bảo 1 khóa học chỉ xuất hiện 1 lần trong 1 giỏ hàng
    add_index :cart_items, [:cart_id, :course_id], unique: true
  end
end
