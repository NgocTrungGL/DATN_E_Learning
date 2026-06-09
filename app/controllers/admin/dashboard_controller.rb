class Admin::DashboardController < Admin::BaseController
  skip_load_and_authorize_resource only: :index
  def index
    @total_students = User.where(role: "student").count
    @total_instructors = User.where(role: "instructor").count
    @total_courses = Course.count
    @published_courses = Course.published.count
    @draft_courses = Course.draft.count
    @pending_courses_count = Course.pending.count

    @pending_enrollments = Enrollment.where(status: "pending")
    @active_enrollments_count = Enrollment.active.count
    @pending_instructor_profiles_count = InstructorProfile.pending.count
    @pending_payouts_count = PayoutRequest.pending.count

    @platform_revenue = WalletTransaction.platform_fee.sum(:amount)
    @revenue_this_month = WalletTransaction.platform_fee
                                           .where("created_at >= ?", Time.current.beginning_of_month)
                                           .sum(:amount)
    @avg_course_rating = Review.average(:rating).to_f.round(1)
  end
end
