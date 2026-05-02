class CreateDiscussionReplies < ActiveRecord::Migration[7.0]
  def change
    create_table :discussion_replies do |t|
      t.references :discussion_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.references :parent, null: true, foreign_key: { to_table: :discussion_replies }

      t.timestamps
    end
  end
end
