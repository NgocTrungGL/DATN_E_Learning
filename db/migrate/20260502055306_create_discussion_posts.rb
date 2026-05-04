class CreateDiscussionPosts < ActiveRecord::Migration[7.0]
  def change
    create_table :discussion_posts do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.string  :title,   null: false
      t.text    :content, null: false
      t.boolean :pinned,  null: false, default: false
      t.boolean :locked,  null: false, default: false
      t.integer :replies_count, null: false, default: 0

      t.timestamps
    end

    add_index :discussion_posts, [:course_id, :pinned, :updated_at],
              name: "idx_discussion_posts_course_pinned_updated"
  end
end
