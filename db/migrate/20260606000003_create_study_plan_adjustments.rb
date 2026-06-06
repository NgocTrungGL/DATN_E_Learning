class CreateStudyPlanAdjustments < ActiveRecord::Migration[7.0]
  def change
    create_table :study_plan_adjustments do |t|
      t.references :study_plan, null: false, foreign_key: true
      t.string :reason
      t.date :old_target_date
      t.date :new_target_date
      t.json :replanned_items
      t.timestamps
    end

    add_index :study_plan_adjustments, [:study_plan_id, :created_at]
  end
end
