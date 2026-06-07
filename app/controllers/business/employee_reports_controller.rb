class Business::EmployeeReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @organization = current_user.organization
    @search_params = employee_search_params
    @q = organization_employee_scope.ransack(@search_params)
    @employees = @q.result(distinct: true).order(:name)
    @selected_employee = @employees.find_by(id: params[:employee_id]) || @employees.first
    @employee_course_progress = []
    @selected_employee_summary = nil

    build_selected_employee_report if @selected_employee
  end

  def suggestions
    @organization = current_user.organization
    query = params[:query].to_s.strip
    employees = employee_suggestions(query)

    render json: employees.map { |employee| employee_suggestion_payload(employee, query) }
  end

  private

  def require_company_admin!
    redirect_to root_path unless current_user.company_admin?
  end

  def organization_employees
    organization_employee_scope.order(:name)
  end

  def organization_employee_scope
    @organization.users.where(role: %i[student employee])
  end

  def employee_suggestions query
    return organization_employee_scope.none if query.blank?

    organization_employee_scope
      .ransack(name_or_email_cont: query)
      .result(distinct: true)
      .order(:name)
      .limit(6)
  end

  def employee_suggestion_payload employee, query
    {
      id: employee.id,
      name: employee.name,
      email: employee.email,
      initial: employee.name.to_s.first&.upcase || "?",
      url: business_employee_reports_path(employee_id: employee.id)
    }
  end

  def employee_search_params
    params.fetch(:q, {}).permit(:name_or_email_cont).to_h
  end

  def build_selected_employee_report
    enrollments = @selected_employee.enrollments.includes(course: [:lessons, :quizzes]).order(created_at: :desc)
    @employee_course_progress = enrollments.map { |enrollment| course_progress_for(enrollment) }

    enrolled_count = @employee_course_progress.size
    completed_count = @employee_course_progress.count { |item| item[:progress_percent] >= 100 }
    avg_progress = enrolled_count.positive? ? (@employee_course_progress.sum { |item| item[:progress_percent] }.to_f / enrolled_count).round : 0
    completed_tests = @employee_course_progress.sum { |item| item[:completed_tests] }
    avg_score_values = @employee_course_progress.filter_map { |item| item[:avg_score] }

    @selected_employee_summary = {
      enrolled_courses: enrolled_count,
      completed_courses: completed_count,
      avg_progress:,
      completed_tests:,
      avg_score: avg_score_values.any? ? (avg_score_values.sum / avg_score_values.size).round(1) : nil
    }
  end

  def course_progress_for enrollment
    course = enrollment.course
    total_lessons = course.lessons.count
    completed_lessons = @selected_employee.progress_trackings
                                          .where(course:, progress_type: :lesson, status: :completed)
                                          .count
    total_tests = course.quizzes.count
    completed_attempts = @selected_employee.quiz_attempts
                                           .completed
                                           .joins(:quiz)
                                           .where(quizzes: { course_id: course.id })
    all_attempts = @selected_employee.quiz_attempts
                                    .joins(:quiz)
                                    .where(quizzes: { course_id: course.id })
    completed_tests = completed_attempts.select(:quiz_id).distinct.count
    avg_score = completed_attempts.average(:score)&.round(1)
    best_score = completed_attempts.maximum(:score)&.round(1)
    latest_attempt = all_attempts.order(Arel.sql("COALESCE(finished_at, started_at) DESC")).first
    last_activity = @selected_employee.progress_trackings
                                      .where(course:)
                                      .order(updated_at: :desc)
                                      .first&.updated_at || latest_attempt&.finished_at || latest_attempt&.started_at
    total_items = total_lessons + total_tests
    completed_items = completed_lessons + completed_tests
    progress_percent = total_items.positive? ? (completed_items.to_f / total_items * 100).round : 0

    {
      course:,
      enrollment:,
      total_lessons:,
      completed_lessons:,
      total_tests:,
      completed_tests:,
      total_attempts: all_attempts.count,
      avg_score:,
      best_score:,
      latest_attempt:,
      last_activity:,
      progress_percent:,
      status: employee_course_status(progress_percent, latest_attempt)
    }
  end

  def employee_course_status progress_percent, latest_attempt
    return "Completed" if progress_percent >= 100
    return "In Progress" if progress_percent.positive? || latest_attempt.present?

    "Not Started"
  end
end
