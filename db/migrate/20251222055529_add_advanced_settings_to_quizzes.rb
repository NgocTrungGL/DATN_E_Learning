class AddAdvancedSettingsToQuizzes < ActiveRecord::Migration[7.0]
  def change
    add_column :quizzes, :easy_count, :integer, default: 0
    add_column :quizzes, :medium_count, :integer, default: 0
    add_column :quizzes, :hard_count, :integer, default: 0

    add_column :quizzes, :scoring_type, :integer, default: 0

    add_column :quiz_answers, :score_earned, :decimal, precision: 5, scale: 2, default: 0.0
  end
end
