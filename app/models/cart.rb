class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :courses, through: :cart_items

  def total_price
    courses.sum{|course| course.price || 0}
  end

  delegate :empty?, to: :cart_items
end
