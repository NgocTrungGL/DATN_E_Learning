class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  # ================= SINGLE COURSE CHECKOUT =================

  def create
    course = Course.find(params[:course_id])

    session = Stripe::Checkout::Session.create(
      locale: "vi",
      payment_method_types: %w(card),
      line_items: [line_item(course)],
      mode: "payment",
      success_url:,
      cancel_url: root_url,
      metadata: single_checkout_metadata(course)
    )

    redirect_to session.url, allow_other_host: true
  end

  # ================= CART CHECKOUT =================

  def create_from_cart
    @cart = current_user.cart
    return if redirect_if_cart_empty

    line_items = build_line_items(@cart)
    session = create_cart_checkout_session(line_items)

    redirect_to session.url, allow_other_host: true
  end

  def success
    @session = Stripe::Checkout::Session.retrieve(params[:session_id])

    if @session.metadata["type"] == "cart"
      current_user.cart.cart_items.destroy_all
      current_user.cart.update(promo_code: nil)
    end

    redirect_to success_url
  end

  private

  # ================= PURCHASE INFO =================

  def quantity
    @quantity ||= begin
      q = params[:quantity].to_i
      q.positive? ? q : 1
    end
  end

  def purchase_type
    @purchase_type ||= params[:purchase_type] || "single"
  end

  def license_discount?
    purchase_type == "license" && quantity >= 10
  end

  # ================= PRICE =================

  def unit_price course
    price = course.price
    price *= 0.9 if license_discount?
    price.to_i
  end

  def formatted_price course
    ActionController::Base.helpers.number_to_currency(
      unit_price(course),
      unit: "đ",
      format: "%n %u",
      precision: 0,
      delimiter: "."
    )
  end

  # ================= PRODUCT =================

  def product_name course
    return course.title unless purchase_type == "license"

    if license_discount?
      "License: #{course.title}
      - SL: #{quantity} (Ưu đãi 10%: #{formatted_price(course)}/vé)"
    else
      "License: #{course.title} (Đơn giá: #{formatted_price(course)})"
    end
  end

  def stripe_image course
    course.thumbnail_url.presence ||
      "https://placehold.co/600x400?text=Course+Image"
  end

  def line_item course
    {
      price_data: {
        currency: "vnd",
        product_data: {
          name: product_name(course),
          description: course.description.to_s.truncate(200),
          images: [stripe_image(course)]
        },
        unit_amount: unit_price(course)
      },
      quantity:
    }
  end

  # ================= METADATA =================

  def single_checkout_metadata course
    data = {
      course_id: course.id,
      user_id: current_user.id,
      purchase_type:,
      quantity:
    }

    data[:organization_id] = current_user.organization.id if purchase_type == "license" && current_user.organization

    data
  end

  def cart_checkout_metadata
    {
      user_id: current_user.id,
      type: "cart",
      course_ids: current_user.cart.course_ids.join(","),
      promo_code: current_user.cart.promo_code
    }
  end

  # ================= CART HELPERS =================

  def redirect_if_cart_empty
    return false if cart_present?

    redirect_to cart_path, alert: "Giỏ hàng trống!"
    true
  end

  def cart_present?
    @cart.present? && @cart.cart_items.any?
  end

  def build_line_items cart
    manual_coupon = active_manual_coupon(cart.promo_code)
    cart.cart_items.map do |item|
      build_cart_line_item(item, discounted_unit_amount(item.course, manual_coupon))
    end
  end

  def active_manual_coupon promo_code
    return if promo_code.blank?

    coupon = Coupon.find_by(code: promo_code)
    coupon if coupon&.active_and_current?
  end

  def discounted_unit_amount course, coupon
    [course.price - cart_item_discount(course, coupon), 0].max.to_i
  end

  def cart_item_discount course, coupon
    discount = automatic_discount(course)
    discount += manual_discount(course, coupon) if coupon
    discount
  end

  def automatic_discount course
    course.has_discount? ? course.price - course.discounted_price : 0
  end

  def manual_discount course, coupon
    return 0 unless manual_coupon_applies?(course, coupon)

    coupon.percentage? ? course.price * coupon.discount_value / 100.0 : coupon.discount_value
  end

  def manual_coupon_applies? course, coupon
    (coupon.specific_course? && coupon.course_id == course.id) ||
      (coupon.global? && !course.has_discount?)
  end

  def build_cart_line_item item, unit_amount
    {
      price_data: {
        currency: "vnd",
        product_data: {
          name: item.course.title,
          images: product_images(item)
        },
        unit_amount:
      },
      quantity: 1
    }
  end

  def product_images item
    return [] if item.course.thumbnail_url.blank?

    [item.course.thumbnail_url]
  end

  def create_cart_checkout_session line_items
    Stripe::Checkout::Session.create(
      locale: "vi",
      payment_method_types: %w(card),
      line_items:,
      mode: "payment",
      metadata: cart_checkout_metadata,
      success_url: success_checkout_url,
      cancel_url: cart_url
    )
  end

  # ================= REDIRECT =================

  def success_url
    purchase_type == "license" ? business_licenses_url : my_courses_url
  end

  def success_checkout_url
    "#{checkout_success_url}?session_id={CHECKOUT_SESSION_ID}"
  end
end
