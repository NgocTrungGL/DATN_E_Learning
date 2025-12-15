class RenameCreatorIdToCreatedByInQuestionsAndQuizzes < ActiveRecord::Migration[7.0]
  def change
    rename_column :questions, :creator_id, :created_by
    rename_column :quizzes, :creator_id, :created_by
  end
end
