class AddStatusToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :status, :integer, default: 0
    add_index :courses, :status
  end
end
