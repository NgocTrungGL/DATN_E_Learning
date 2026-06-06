class AddLessonTypeAndContentAndResourcesToLessons < ActiveRecord::Migration[7.0]
  def change
    add_column :lessons, :lesson_type, :integer
    add_column :lessons, :content, :text
    add_column :lessons, :resources, :json
  end
end
