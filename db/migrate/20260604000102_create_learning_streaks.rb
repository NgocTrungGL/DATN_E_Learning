class CreateLearningStreaks < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_streaks do |t|
      t.references :user, null: false, foreign_key: true, unique: true
      t.integer :current_streak, default: 0
      t.integer :longest_streak, default: 0
      t.date :last_activity_date
      t.integer :weekly_activity_days, default: 0
      t.timestamps
    end
  end
end
