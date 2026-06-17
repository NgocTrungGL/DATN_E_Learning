class AddInvoiceToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_reference :licenses, :invoice, foreign_key: true
  end
end
