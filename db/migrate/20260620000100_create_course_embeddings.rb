class CreateCourseEmbeddings < ActiveRecord::Migration[7.0]
  def change
    create_table :course_embeddings do |t|
      t.references :course, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :embedding, null: false, default: []
      t.string :content_hash, null: false
      t.datetime :embedded_at, null: false
      t.timestamps
    end

    add_index :course_embeddings, :content_hash
  end
end
