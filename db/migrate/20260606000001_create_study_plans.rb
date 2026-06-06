class CreateStudyPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :study_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.date :goal_deadline
      t.integer :target_days
      t.json :preferred_study_times
      t.string :status, default: "active"
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :study_plans, [:user_id, :status]
    add_index :study_plans, [:user_id, :course_id], unique: true
  end
end
