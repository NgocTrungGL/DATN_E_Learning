class CreateCoupons < ActiveRecord::Migration[7.0]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.integer :discount_type, default: 0 # 0: percentage, 1: fixed_amount
      t.decimal :discount_value, precision: 10, scale: 2, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.integer :target_type, default: 0 # 0: global, 1: specific_course
      t.references :course, null: true, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.integer :usage_limit, default: 0 # 0: unlimited
      t.integer :status, default: 0 # 0: active, 1: inactive

      t.timestamps
    end
    add_index :coupons, :code, unique: true
  end
end
