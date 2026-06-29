class RemoveSkillBasedPersonalization < ActiveRecord::Migration[7.0]
  def up
    # Loại bỏ nhánh cá nhân hóa dựa trên quiz-skill để chuyển sang hướng hành vi học tập.
    drop_table :adaptive_study_plan_proposals, if_exists: true
    drop_table :skill_mastery_events, if_exists: true
    drop_table :user_skill_masteries, if_exists: true
    drop_table :question_skills, if_exists: true
    drop_table :lesson_skills, if_exists: true
    drop_table :skill_prerequisites, if_exists: true
    drop_table :skills, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
