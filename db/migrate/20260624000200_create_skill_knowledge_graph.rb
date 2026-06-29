class CreateSkillKnowledgeGraph < ActiveRecord::Migration[7.0]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end
    add_index :skills, :name, unique: true
    add_index :skills, :slug, unique: true

    create_table :skill_prerequisites do |t|
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.references :prerequisite_skill, null: false,
                    foreign_key: { to_table: :skills, on_delete: :cascade }
      t.decimal :strength, precision: 4, scale: 3, null: false, default: 1.0

      t.timestamps
    end
    add_index :skill_prerequisites,
              [:skill_id, :prerequisite_skill_id],
              unique: true,
              name: "index_unique_skill_prerequisites"
    add_check_constraint :skill_prerequisites,
                         "skill_id <> prerequisite_skill_id",
                         name: "check_skill_prerequisite_not_self"
    add_check_constraint :skill_prerequisites,
                         "strength > 0 AND strength <= 1",
                         name: "check_skill_prerequisite_strength"

    create_table :lesson_skills do |t|
      t.references :lesson, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :coverage_weight, precision: 4, scale: 3,
                null: false, default: 1.0

      t.timestamps
    end
    add_index :lesson_skills, [:lesson_id, :skill_id], unique: true
    add_check_constraint :lesson_skills,
                         "coverage_weight > 0 AND coverage_weight <= 1",
                         name: "check_lesson_skill_coverage_weight"

    create_table :question_skills do |t|
      t.references :question, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :assessment_weight, precision: 4, scale: 3,
                null: false, default: 1.0

      t.timestamps
    end
    add_index :question_skills, [:question_id, :skill_id], unique: true
    add_check_constraint :question_skills,
                         "assessment_weight > 0 AND assessment_weight <= 1",
                         name: "check_question_skill_assessment_weight"
  end
end
