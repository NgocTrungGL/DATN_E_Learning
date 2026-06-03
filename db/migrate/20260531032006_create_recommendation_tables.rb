class CreateRecommendationTables < ActiveRecord::Migration[7.0]
  def change
    create_table :user_recommendations do |t|
      t.bigint :user_id, null: false
      t.bigint :course_id, null: false
      t.decimal :score, precision: 8, scale: 4
      t.string :reason_type  # "cf" | "content" | "popular"
      t.datetime :computed_at, null: false
      t.timestamps
    end

    create_table :course_similarities do |t|
      t.bigint :course_a_id, null: false
      t.bigint :course_b_id, null: false
      t.decimal :score, precision: 8, scale: 6, null: false  # 0.0 – 1.0
      t.datetime :computed_at
      t.timestamps
    end

    add_index :user_recommendations, [:user_id, :score]
    add_index :user_recommendations, [:user_id, :course_id], unique: true
    add_foreign_key :user_recommendations, :users, on_delete: :cascade
    add_foreign_key :user_recommendations, :courses, on_delete: :cascade

    add_index :course_similarities, [:course_a_id, :score]
    add_index :course_similarities, [:course_a_id, :course_b_id], unique: true
    add_foreign_key :course_similarities, :courses, column: :course_a_id, on_delete: :cascade
    add_foreign_key :course_similarities, :courses, column: :course_b_id, on_delete: :cascade
  end
end
