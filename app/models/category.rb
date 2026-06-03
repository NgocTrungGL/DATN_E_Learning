class Category < ApplicationRecord
  belongs_to :parent, class_name: Category.name, optional: true
  has_many :subcategories, class_name: Category.name, foreign_key: "parent_id",
dependent: :nullify

  has_many :courses, dependent: :nullify
  has_many :children, class_name: Category.name, foreign_key: "parent_id",
dependent: :nullify

  scope :roots, -> { where(parent_id: nil) }

  def descendants
    self.class.where(parent_id: id)
  end

  def ancestor_ids
    ids = []
    cat = self
    while cat.parent.present?
      ids << cat.parent_id
      cat = cat.parent
    end
    ids
  end

  def all_child_ids
    descendants.pluck(:id)
  end

  # Validation
  validates :name, presence: true, uniqueness: true
end
