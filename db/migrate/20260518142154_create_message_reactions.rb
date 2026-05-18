class CreateMessageReactions < ActiveRecord::Migration[7.0]
  def change
    create_table :message_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :discussion_message, null: false, foreign_key: true
      t.string :emoji, null: false

      t.timestamps
    end

    add_index :message_reactions, [:user_id, :discussion_message_id, :emoji], unique: true, name: "index_msg_reactions_on_user_and_msg_and_emoji"
  end
end
