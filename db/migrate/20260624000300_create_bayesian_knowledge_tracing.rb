class CreateBayesianKnowledgeTracing < ActiveRecord::Migration[7.0]
  def change
    add_column :skills, :bkt_initial_probability, :decimal,
               precision: 6, scale: 5, null: false, default: 0.2
    add_column :skills, :bkt_learning_probability, :decimal,
               precision: 6, scale: 5, null: false, default: 0.1
    add_column :skills, :bkt_guess_probability, :decimal,
               precision: 6, scale: 5, null: false, default: 0.2
    add_column :skills, :bkt_slip_probability, :decimal,
               precision: 6, scale: 5, null: false, default: 0.1

    add_check_constraint :skills,
                         bkt_probability_constraint,
                         name: "check_skill_bkt_probabilities"

    create_table :user_skill_masteries do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :probability, precision: 6, scale: 5,
                null: false, default: 0.2
      t.integer :observations_count, null: false, default: 0
      t.integer :correct_count, null: false, default: 0
      t.datetime :last_practiced_at

      t.timestamps
    end
    add_index :user_skill_masteries, [:user_id, :skill_id], unique: true
    add_check_constraint :user_skill_masteries,
                         "probability >= 0 AND probability <= 1",
                         name: "check_user_skill_mastery_probability"

    create_table :skill_mastery_events do |t|
      t.references :user_skill_mastery, null: false,
                   foreign_key: { on_delete: :cascade }
      t.references :quiz_attempt, null: false,
                   foreign_key: { on_delete: :cascade }
      t.references :quiz_answer, null: false,
                   foreign_key: { on_delete: :cascade }
      t.references :question, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :prior_probability, precision: 6, scale: 5, null: false
      t.decimal :posterior_probability, precision: 6, scale: 5, null: false
      t.decimal :assessment_weight, precision: 4, scale: 3, null: false
      t.boolean :observed_correct, null: false
      t.jsonb :parameters, null: false, default: {}
      t.datetime :observed_at, null: false

      t.timestamps
    end
    add_index :skill_mastery_events,
              [:quiz_answer_id, :skill_id],
              unique: true,
              name: "index_unique_mastery_event_per_answer_skill"
  end

  private

  def bkt_probability_constraint
    <<~SQL.squish
      bkt_initial_probability BETWEEN 0 AND 1 AND
      bkt_learning_probability BETWEEN 0 AND 1 AND
      bkt_guess_probability BETWEEN 0 AND 1 AND
      bkt_slip_probability BETWEEN 0 AND 1
    SQL
  end
end
