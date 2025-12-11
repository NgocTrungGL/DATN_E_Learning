class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def create
    course = Course.find(params[:course_id])
    enrollment = find_or_build_enrollment(course)

    update_enrollment(enrollment, course)
    session = build_stripe_session(course, enrollment)

    redirect_to session.url, allow_other_host: true
  end
  private

  def find_or_build_enrollment course
    current_user.enrollments.find_by(course:) ||
      current_user.enrollments.create(course:)
  end

  def update_enrollment enrollment, course
    enrollment.update(
      price: course.price,
      status: :pending
    )
  end

  def build_stripe_session course, enrollment
    Stripe::Checkout::Session.create(
      payment_method_types: %w(card),
      line_items: [stripe_line_item(course)],
      mode: "payment",
      success_url: course_url(course, success: true),
      cancel_url: course_url(course, canceled: true),
      metadata: stripe_metadata(course, enrollment)
    )
  end

  def stripe_line_item course
    {
      price_data: {
        currency: "vnd",
        product_data: {
          name: course.title,
          description: course.description&.truncate(100),
          images: [course.thumbnail_url].compact
        },
        unit_amount: course.price.to_i
      },
      quantity: 1
    }
  end

  def stripe_metadata course, enrollment
    {
      enrollment_id: enrollment.id,
      user_id: current_user.id,
      course_id: course.id
    }
  end
end
