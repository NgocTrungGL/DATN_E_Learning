class AddUploadTypeToLessons < ActiveRecord::Migration[7.0]
  def change
    add_column :lessons, :upload_type, :integer, default: 0, null: false
    add_index :lessons, :upload_type
  end
end
