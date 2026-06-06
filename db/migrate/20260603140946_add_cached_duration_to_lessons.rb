class AddCachedDurationToLessons < ActiveRecord::Migration[7.0]
  def change
    add_column :lessons, :cached_duration_seconds, :integer
  end
end
