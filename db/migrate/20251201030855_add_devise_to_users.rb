class AddDeviseToUsers < ActiveRecord::Migration[7.0]
  def up
    change_table :users do |t|
      t.rename :password_digest, :encrypted_password

      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      t.datetime :remember_created_at


      t.string   :confirmation_token
      t.datetime :confirmation_sent_at
    end

    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
  end

  def down
    change_table :users do |t|
      t.rename :encrypted_password, :password_digest
      t.remove :reset_password_token, :reset_password_sent_at, :remember_created_at, :confirmation_token, :confirmation_sent_at
    end
  end
end
