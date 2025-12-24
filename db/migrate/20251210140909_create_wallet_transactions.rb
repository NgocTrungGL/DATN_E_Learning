class CreateWalletTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :wallet_transactions do |t|
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2
      t.integer :transaction_type
      t.string :source_type
      t.integer :source_id

      t.timestamps
    end
  end
end
