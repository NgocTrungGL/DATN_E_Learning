class AddParentIdToDiscussionMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :discussion_messages, :parent_id, :integer, null: true, default: nil
    add_index :discussion_messages, :parent_id
    add_column :discussion_messages, :replies_count, :integer, null: false, default: 0
  end
end
