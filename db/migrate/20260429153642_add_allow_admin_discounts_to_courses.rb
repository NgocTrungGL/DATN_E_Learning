class AddAllowAdminDiscountsToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :allow_admin_discounts, :boolean, default: true
  end
end
