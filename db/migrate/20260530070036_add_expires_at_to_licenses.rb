class AddExpiresAtToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :expires_at, :datetime
  end
end
