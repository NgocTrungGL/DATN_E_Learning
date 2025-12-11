class AddPhoneToInstructorProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :instructor_profiles, :phone, :string
  end
end
