class AddUsageCountToCoupons < ActiveRecord::Migration[7.0]
  def change
    add_column :coupons, :usage_count, :integer, default: 0
  end
end
