class AddExternalReferenceToWalletTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column :wallet_transactions, :external_reference, :string
    add_index :wallet_transactions, :external_reference, unique: true
  end
end
