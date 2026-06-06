class CreateStudyPlanItems < ActiveRecord::Migration[7.0]
  def change
    create_table :study_plan_items do |t|
      t.references :study_plan, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.date :scheduled_date
      t.time :scheduled_start_time
      t.integer :estimated_duration_minutes
      t.integer :order_in_course
      t.string :status, default: "pending"
      t.datetime :actual_completed_at
      t.boolean :is_replan_needed, default: false
      t.timestamps
    end

    add_index :study_plan_items, [:study_plan_id, :scheduled_date]
    add_index :study_plan_items, [:study_plan_id, :status]
  end
end
