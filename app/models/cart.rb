class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :courses, through: :cart_items

  def total_price
    courses.sum{|course| course.price || 0}
  end

  def discount_amount
    manual_coupon = active_manual_coupon
    cart_items.sum do |item|
      course = item.course
      [item_discount(course, manual_coupon), course.price].min
    end
  end

  def final_total
    [total_price - discount_amount, 0].max
  end

  delegate :empty?, to: :cart_items

  private

  def active_manual_coupon
    return if promo_code.blank?

    coupon = Coupon.find_by(code: promo_code)
    coupon if coupon&.active_and_current?
  end

  def item_discount course, coupon
    discount = automatic_discount(course)
    discount += manual_discount(course, coupon) if coupon
    discount
  end

  def automatic_discount course
    course.has_discount? ? course.price - course.discounted_price : 0
  end

  def manual_discount course, coupon
    return 0 unless manual_discount_applies?(course, coupon)

    coupon.percentage? ? course.price * coupon.discount_value / 100.0 : coupon.discount_value
  end

  def manual_discount_applies? course, coupon
    (coupon.specific_course? && coupon.course_id == course.id) ||
      (coupon.global? && !course.has_discount?)
  end

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
