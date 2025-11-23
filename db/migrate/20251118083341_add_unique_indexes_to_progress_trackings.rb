class AddUniqueIndexesToProgressTrackings < ActiveRecord::Migration[7.0]
  def change
    # (Một user không thể có 2 dòng tiến độ cho cùng 1 bài học)
    add_index :progress_trackings, [:user_id, :lesson_id], unique: true
    # (Một user không thể có 2 dòng tiến độ cho cùng 1 bài quiz)
    add_index :progress_trackings, [:user_id, :quiz_id], unique: true
  end
end
