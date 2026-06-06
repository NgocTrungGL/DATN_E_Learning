class PublicInstructorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @instructor = User.where(role: :instructor).find(params[:id])
    @courses = @instructor.created_courses
                         .published
                         .includes(:reviews, :enrollments)
                         .order(created_at: :desc)

    total_students = @courses.sum { |c| c.enrollments.active.count }
    ratings = @courses.map { |c| c.reviews.average(:rating) }.compact
    avg_rating = ratings.sum.to_f / ratings.size if ratings.any?
    @stats = {
      total_students:,
      total_courses: @courses.count,
      avg_rating: avg_rating.to_f.round(1),
      total_reviews: @courses.sum { |c| c.reviews.count }
    }
  end
end
