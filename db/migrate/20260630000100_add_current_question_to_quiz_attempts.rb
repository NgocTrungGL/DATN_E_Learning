class AddCurrentQuestionToQuizAttempts < ActiveRecord::Migration[7.0]
  def change
    add_reference :quiz_attempts, :current_question,
                  foreign_key: { to_table: :questions, on_delete: :nullify },
                  index: true
  end
end
