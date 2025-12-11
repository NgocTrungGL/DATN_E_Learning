class AddPriceToEnrollments < ActiveRecord::Migration[7.0]
  def change
    add_column :enrollments, :price, :decimal, precision: 15, scale: 2
  end
end
