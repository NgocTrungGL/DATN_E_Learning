class CreateCourseLearningOutcomes < ActiveRecord::Migration[7.0]
  def change
    create_table :course_learning_outcomes do |t|
      t.references :course, null: false, foreign_key: true, index: true
      t.string :content, null: false
      t.integer :order_index, default: 0
      t.timestamps
    end

    add_index :course_learning_outcomes, [:course_id, :order_index]
  end
end
