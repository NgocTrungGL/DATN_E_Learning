class ChangeLessonIdNullableInQuizzes < ActiveRecord::Migration[7.0]
  def change
    change_column_null :quizzes, :lesson_id, true
  end
end
