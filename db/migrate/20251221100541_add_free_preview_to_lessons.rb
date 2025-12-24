class AddFreePreviewToLessons < ActiveRecord::Migration[7.0]
  def change
    add_column :lessons, :free_preview, :boolean, default: false
  end
end
