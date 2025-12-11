class Admin::DashboardController < Admin::BaseController
  skip_load_and_authorize_resource only: :index
  def index
    @total_students = User.where(role: "student").count
    @total_instructors = User.where(role: "instructor").count
    @total_courses = Course.count

    @pending_enrollments = Enrollment.where(status: "pending")

    @latest_users = User.order(created_at: :desc).limit(5)
    @latest_reviews = Review.includes(:user,
                                      :course).order(created_at: :desc).limit(5)
  end
end
