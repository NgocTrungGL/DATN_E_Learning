class Category < ApplicationRecord
  belongs_to :parent, class_name: Category.name, optional: true
  has_many :subcategories, class_name: Category.name, foreign_key: "parent_id",
dependent: :nullify

  has_many :courses, dependent: :nullify
  has_many :children, class_name: Category.name, foreign_key: "parent_id",
dependent: :nullify
  # Validation
  validates :name, presence: true, uniqueness: true
end
