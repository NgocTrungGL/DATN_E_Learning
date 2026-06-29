class CreateAdaptiveStudyPlanProposals < ActiveRecord::Migration[7.0]
  def change
    create_table :adaptive_study_plan_proposals do |t|
      t.references :study_plan, null: false,
                                foreign_key: { on_delete: :cascade }
      t.references :study_plan_item, null: true,
                                     foreign_key: { on_delete: :nullify }
      t.references :lesson, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.string :status, null: false, default: "pending"
      t.string :reason_type, null: false
      t.decimal :priority, precision: 6, scale: 5, null: false
      t.bigint :latest_mastery_event_id
      t.json :details, null: false, default: {}
      t.datetime :decided_at

      t.timestamps
    end

    add_index :adaptive_study_plan_proposals,
              [:study_plan_id, :lesson_id],
              unique: true,
              name: "index_unique_adaptive_plan_proposals"
    add_index :adaptive_study_plan_proposals,
              [:study_plan_id, :status],
              name: "index_adaptive_proposals_on_plan_and_status"

    add_column :study_plan_adjustments, :details, :json,
               null: false, default: {}
  end
end
