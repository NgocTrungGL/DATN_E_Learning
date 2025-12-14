class AddUniqueIndexToOrganizationsName < ActiveRecord::Migration[7.0]
  def change
    add_index :organizations, :name, unique: true

    add_index :organizations, :domain, unique: true
  end
end
