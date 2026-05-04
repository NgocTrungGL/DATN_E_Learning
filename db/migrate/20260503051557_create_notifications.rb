class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.string :notification_type
      t.datetime :read_at
      t.references :actionable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
