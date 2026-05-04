class CreateDiscussionMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :discussion_messages do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :discussion_messages, [:course_id, :created_at]
  end
end
