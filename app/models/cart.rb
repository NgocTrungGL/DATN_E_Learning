class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :courses, through: :cart_items

  def total_price
    courses.sum{|course| course.price || 0}
  end

  def discount_amount
    total_disc = 0
    manual_coupon = Coupon.find_by(code: promo_code) if promo_code.present?
    manual_coupon = nil unless manual_coupon&.active_and_current?

    cart_items.each do |item|
      item_disc = 0
      course = item.course

      # 1. Automatic Global Discount
      if course.has_discount?
        item_disc += (course.price - course.discounted_price)
      end

      # 2. Manual Coupon (Special)
      if manual_coupon
        if manual_coupon.specific_course? && manual_coupon.course_id == course.id
          # Applies to specific course
          manual_item_disc = manual_coupon.percentage? ? (course.price * manual_coupon.discount_value / 100.0) : manual_coupon.discount_value
          item_disc += manual_item_disc
        elsif manual_coupon.global? && !course.has_discount?
          # If it's a manual global code and course doesn't have an auto one
          # Or if it's BETTER than the auto one?
          # For now, let's say manual global only applies if no auto global exists
          # Actually, let's just apply it if it's global and creator is Admin.
          manual_item_disc = manual_coupon.percentage? ? (course.price * manual_coupon.discount_value / 100.0) : manual_coupon.discount_value
          item_disc += manual_item_disc
        end
      end

      total_disc += [item_disc, course.price].min
    end

    total_disc
  end

  def final_total
    [total_price - discount_amount, 0].max
  end

  delegate :empty?, to: :cart_items

  private

  def coupon_applies_to? coupon, course
    if coupon.global?
      # Global admin coupons apply to admin courses or instructor courses that allow it
      coupon.creator.admin? && (course.creator&.admin? || course.allow_admin_discounts?)
    else
      # Specific course coupons
      coupon.course_id == course.id
    end
  end
end
