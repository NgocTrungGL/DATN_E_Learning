class CreateLearningActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, foreign_key: true, optional: true
      t.references :lesson, foreign_key: true, optional: true
      t.string :activity_type, null: false
      t.integer :duration_seconds, default: 0
      t.integer :score, optional: true
      t.date :activity_date, null: false
      t.timestamps
    end

    add_index :learning_activities, [:user_id, :activity_date]
    add_index :learning_activities, [:user_id, :activity_type]
  end
end
