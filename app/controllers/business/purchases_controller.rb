class Business::PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def new
    course_id = params[:course_id]
    @course = Course.find_by(id: course_id)

    redirect_to business_course_market_index_path, alert: "Course not found." unless @course

    @quantity = params[:quantity].to_i.clamp(1, 100)
    @unit_price = calculate_unit_price(@course)
    @total_price = @unit_price * @quantity
    @discount = @course.price * @quantity - @total_price
  end

  def create
    @course = Course.find(params[:course_id])
    @quantity = params[:quantity].to_i.clamp(1, 100)
    @unit_price = calculate_unit_price(@course)
    @total_price = @unit_price * @quantity

    session = Stripe::Checkout::Session.create(
      locale: "vi",
      payment_method_types: %w(card),
      line_items: [build_line_item],
      mode: "payment",
      success_url: business_licenses_url,
      cancel_url: business_course_market_url,
      metadata: {
        course_id: @course.id,
        user_id: current_user.id,
        purchase_type: "license",
        quantity: @quantity,
        organization_id: current_user.organization.id
      }
    )

    redirect_to session.url, allow_other_host: true
  end

  private

  def require_company_admin!
    redirect_to root_path unless current_user.company_admin?
  end

  def calculate_unit_price course
    price = course.price
    price *= 0.9 if @quantity.to_i >= 10
    price.to_i
  end

  def build_line_item
    {
      price_data: {
        currency: "vnd",
        product_data: {
          name: "License: #{@course.title}",
          description: "Business License - Qty: #{@quantity}",
          images: [@course.thumbnail_url.presence || "https://placehold.co/600x400?text=Course+Image"]
        },
        unit_amount: @unit_price
      },
      quantity: @quantity
    }
  end
end
