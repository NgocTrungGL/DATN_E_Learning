class RemoveUnusedStudyPlanAdjustmentDetails < ActiveRecord::Migration[7.0]
  def change
    # Cột này thuộc thử nghiệm cá nhân hóa theo quiz-skill, flow hiện tại không còn sử dụng.
    remove_column :study_plan_adjustments, :details, :json, if_exists: true
  end
end
