class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.string :stripe_session_id
      t.string :stripe_payment_intent
      t.integer :status, default: 0
      t.string :invoice_number
      t.datetime :paid_at

      t.timestamps
    end

    add_index :invoices, :stripe_session_id
    add_index :invoices, [:organization_id, :created_at]
  end
end
