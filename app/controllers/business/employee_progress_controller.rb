class Business::EmployeeProgressController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def show
    @employee = User.find(params[:id])
    @organization = current_user.organization

    raise ActiveRecord::RecordNotFound unless @employee.organization_id == @organization.id

    @enrollments = @employee.enrollments
                             .includes(:course)
                             .order(created_at: :desc)

    total_duration = @employee.progress_trackings.sum(:progress_value) || 0
    avg_score = @employee.quiz_attempts.completed.average(:score)&.round(1) || 0

    @stats = {
      enrolled_courses: @enrollments.count,
      completed_courses: @enrollments.where(status: :completed).count,
      total_time_spent: 0,
      avg_score: avg_score
    }

    @course_progress = @enrollments.map do |enrollment|
      course = enrollment.course
      completed_lessons = ProgressTracking.where(user: @employee, course: course, status: :completed).count
      total_lessons = course.lessons.count

      quiz = course.quizzes.first
      quiz_attempt = quiz&.quiz_attempts&.where(user: @employee)&.completed&.last

      {
        course: course,
        enrollment: enrollment,
        progress_percent: total_lessons.positive? ? (completed_lessons.to_f / total_lessons * 100).round : 0,
        completed_lessons: completed_lessons,
        total_lessons: total_lessons,
        quiz_attempt: quiz_attempt,
        last_activity: ProgressTracking.where(user: @employee, course: course).order(updated_at: :desc).first&.updated_at
      }
    end
  end

  def export
    @employee = User.find(params[:id])
    @organization = current_user.organization

    raise ActiveRecord::RecordNotFound unless @employee.organization_id == @organization.id

    enrollments = @employee.enrollments.includes(:course).order(created_at: :desc)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Course", "Enrolled Date", "Progress (%)", "Lessons Completed",
              "Total Lessons", "Quiz Score", "Status", "Last Activity"]

      enrollments.each do |enrollment|
        course = enrollment.course
        completed = ProgressTracking.where(user: @employee, course: course, status: :completed).count
        total = course.lessons.count
        progress = total.positive? ? (completed.to_f / total * 100).round : 0
        quiz = course.quizzes.first
        attempt = quiz&.quiz_attempts&.where(user: @employee)&.completed&.last
        quiz_score = attempt&.score&.round || "N/A"
        last_activity = ProgressTracking.where(user: @employee, course: course)
                                        .order(updated_at: :desc).first&.updated_at
        status = progress >= 100 ? "Completed" : (progress > 0 ? "In Progress" : "Not Started")

        csv << [
          course.title,
          enrollment.created_at.strftime("%d/%m/%Y"),
          "#{progress}%",
          "#{completed}/#{total}",
          quiz_score,
          status,
          last_activity ? last_activity.strftime("%d/%m/%Y %H:%M") : "N/A"
        ]
      end
    end

    send_data csv_data, filename: "progress_#{@employee.name.gsub(' ', '_')}.csv",
              type: "text/csv", disposition: "attachment"
  end

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path, alert: "Bạn không có quyền truy cập."
  end
end
