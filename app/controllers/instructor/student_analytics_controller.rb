class Instructor::StudentAnalyticsController < Instructor::BaseController
  def index
    @courses = current_user.created_courses
                         .published
                         .includes(:enrollments, :course_modules, :quizzes)
                         .order(created_at: :desc)

    @courses_data = @courses.map do |course|
      {
        course:,
        total_students: course.enrollments.count,
        active_students: course.enrollments.active.count,
        avg_progress: course.average_progress_percentage,
        avg_quiz_score: course.average_quiz_score
      }
    end
  end

  def show
    @course = current_user.created_courses.find(params[:id])
    authorize! :manage, @course

    @search = params[:q].presence
    @status_filter = params[:status].presence

    enrollment_scope = @course.enrollments.includes(:user)

    if @search.present?
      enrollment_scope = enrollment_scope
        .where("users.name ILIKE ? OR users.email ILIKE ?", "%#{@search}%", "%#{@search}%")
    end

    case @status_filter
    when "active"
      enrollment_scope = enrollment_scope.where(status: :active)
    when "completed"
      completed_user_ids = @course.progress_trackings
        .completed.select(:user_id).distinct.pluck(:user_id)
      enrollment_scope = enrollment_scope.where(user_id: completed_user_ids)
    when "inactive"
      enrollment_scope = enrollment_scope
        .where(status: :active)
        .where.not(user_id: @course.progress_trackings.select(:user_id))
    end

    @pagy, @enrollments = pagy(enrollment_scope.order(created_at: :desc), items: 20)

    @total_students = @course.enrollments.count
    @active_students = @course.enrollments.active.count
    completed_ids = @course.progress_trackings.completed.select(:user_id).distinct.pluck(:user_id)
    @completed_students = @course.enrollments.where(user_id: completed_ids).count
    @avg_progress = @course.average_progress_percentage
    @avg_quiz_score = @course.average_quiz_score

    @enrollment_trend = build_enrollment_trend

    completed = @completed_students
    in_progress = [@active_students - completed, 0].max
    not_started = @total_students - @active_students
    @completion_chart = {
      "Hoan thanh" => completed,
      "Dang hoc" => in_progress,
      "Chua hoc" => not_started
    }
  end

  private

  def build_enrollment_trend
    start_date = 12.weeks.ago.to_date
    end_date = Date.today
    trend = Hash.new(0)

    @course.enrollments
      .where("DATE(created_at) >= ?", start_date)
      .where("DATE(created_at) <= ?", end_date)
      .pluck("DATE(created_at)")
      .each { |d| trend[d.to_s] += 1 }

    trend.sort.to_h
  end
end
