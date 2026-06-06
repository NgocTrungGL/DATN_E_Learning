class CreateLearningGoals < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :goal_type, null: false
      t.integer :target_value, null: false
      t.integer :current_value, default: 0
      t.date :week_start, null: false
      t.boolean :is_active, default: true
      t.timestamps
    end

    add_index :learning_goals, [:user_id, :week_start, :goal_type], unique: true
  end
end
