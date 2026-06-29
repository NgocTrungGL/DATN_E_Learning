class DeduplicateLessonCompletionActivities < ActiveRecord::Migration[7.0]
  INDEX_NAME = "index_unique_lesson_completion_activities".freeze

  def up
    execute <<~SQL.squish
      WITH ranked_completions AS (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY user_id, lesson_id
                 ORDER BY id
               ) AS duplicate_position
        FROM learning_activities
        WHERE activity_type = 'lesson_complete'
          AND lesson_id IS NOT NULL
      )
      DELETE FROM learning_activities
      WHERE id IN (
        SELECT id
        FROM ranked_completions
        WHERE duplicate_position > 1
      )
    SQL

    add_index :learning_activities,
              [:user_id, :lesson_id, :activity_type],
              unique: true,
              where: "activity_type = 'lesson_complete' AND lesson_id IS NOT NULL",
              name: INDEX_NAME
  end

  def down
    remove_index :learning_activities, name: INDEX_NAME
  end
end
