class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :course

  validates :course_id,
            uniqueness: { scope: :cart_id, message: "đã có trong giỏ hàng" }

  after_commit :queue_recommendation_update, on: [:create, :destroy]

  def queue_recommendation_update
    Recommendations::CacheInvalidator.call(cart.user_id)
  end
end
