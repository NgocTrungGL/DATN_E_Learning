class Instructor::CoursePerformanceController < Instructor::BaseController
  def index
    @courses = current_user.created_courses
                         .includes(:enrollments, :reviews)
                         .order(created_at: :desc)

    @courses_data = @courses.map do |course|
      { course:, chart: build_monthly_enrollments(course) }
    end
  end

  def show
    @course = current_user.created_courses.find(params[:id])

    # Revenue trend (manual, avoid groupdate MySQL issue)
    start_date = 6.months.ago.to_date
    end_date = Date.today
    revenue_trend = Hash.new(0)
    @course.enrollments
      .where("DATE(created_at) >= ?", start_date)
      .where("DATE(created_at) <= ?", end_date)
      .pluck("DATE(created_at)", "price")
      .each { |d, p| revenue_trend[d.to_s] += (p.to_f * 0.7).round }
    @monthly_revenue = revenue_trend.sort.to_h

    @rating_distribution = @course.reviews.group(:rating).count

    enrollment_count = @course.enrollments.count
    completed_count = @course.progress_trackings.completed.select(:user_id).distinct.count(:user_id)
    @enrollment_vs_completion = {
      "Da enroll" => enrollment_count,
      "Hoan thanh" => completed_count
    }
  end

  private

  def build_monthly_enrollments(course)
    start_date = 6.months.ago.to_date
    end_date = Date.today
    trend = Hash.new(0)
    course.enrollments
      .where("DATE(created_at) >= ?", start_date)
      .where("DATE(created_at) <= ?", end_date)
      .pluck("DATE(created_at)")
      .each { |d| trend[d.to_s] += 1 }
    trend.sort.to_h
  end
end
