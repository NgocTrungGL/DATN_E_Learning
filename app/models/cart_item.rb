class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :course

  validates :course_id,
            uniqueness: {scope: :cart_id, message: "đã có trong giỏ hàng"}
end
