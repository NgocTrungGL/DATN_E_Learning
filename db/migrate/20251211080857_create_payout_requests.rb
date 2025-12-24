class CreatePayoutRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :payout_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, default: 0
      t.integer :status
      t.text :bank_info
      t.text :note

      t.timestamps
    end
  end
end
