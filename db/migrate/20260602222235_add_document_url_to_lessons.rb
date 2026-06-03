class AddDocumentUrlToLessons < ActiveRecord::Migration[7.0]
  def change
    add_column :lessons, :document_url, :string
  end
end
