class CreateCertificates < ActiveRecord::Migration[7.0]
  def change
    create_table :certificates do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :certificate_code, null: false
      t.datetime :issued_at, null: false
      t.string :template_type, default: "classic"

      t.timestamps
    end

    add_index :certificates, :certificate_code, unique: true
    add_index :certificates, %i[user_id course_id], unique: true
  end
end
