class CreateLicenses < ActiveRecord::Migration[7.0]
  def change
    create_table :licenses do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.string :code
      t.integer :status, default: 0
      t.decimal :price, precision: 10, scale: 2

      t.timestamps
    end

    add_index :licenses, [:organization_id, :course_id, :status]
  end
end
