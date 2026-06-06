class Business::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @organization = current_user.organization
    @employees = @organization.users.where(role: :student)

    build_overview_stats
    build_course_stats
    build_employee_stats
    build_monthly_trends
  end

  private

  def require_company_admin!
    redirect_to root_path unless current_user.company_admin?
  end

  def build_overview_stats
    @total_licenses = @organization.licenses.count
    @assigned_licenses = @organization.licenses.where(status: :assigned).count
    @available_licenses = @organization.licenses.where(status: :available).count
    @expired_licenses = @organization.licenses.where(status: :expired).count
    @total_spent = @organization.invoices.where(status: :paid).sum(:total_amount)
    @active_employees = @employees.joins(:enrollments).distinct.count(:id)
    @avg_completion = calculate_avg_completion
    @compliance_rate = calculate_compliance_rate
  end

  def build_course_stats
    @course_stats = []

    @organization.licenses.group(:course_id).count.each do |course_id, total_licenses|
      course = Course.find_by(id: course_id)
      next unless course

      assigned = @organization.licenses.where(course_id:, status: :assigned).count
      completed = Enrollment.joins(:user)
                           .where(users: { organization_id: @organization.id, role: :student })
                           .where(course_id:)
                           .where(status: :completed).count

      @course_stats << {
        course: course,
        total_licenses: total_licenses,
        assigned: assigned,
        completed: completed,
        completion_rate: assigned.positive? ? (completed.to_f / assigned * 100).round : 0
      }
    end

    @course_stats.sort_by! { |s| -s[:total_licenses] }
  end

  def build_employee_stats
    @top_employees = @employees.map do |emp|
      enrollments = emp.enrollments
      completed = enrollments.where(status: :completed).count
      total = enrollments.count
      progress = total.positive? ? (completed.to_f / total * 100).round : 0
      avg_score = emp.quiz_attempts.completed.average(:score)&.round(1) || 0

      {
        employee: emp,
        enrolled: total,
        completed: completed,
        progress: progress,
        avg_score: avg_score,
        last_activity: emp.progress_trackings.order(updated_at: :desc).first&.updated_at
      }
    end.sort_by { |e| -e[:progress] }.first(10)
  end

  def build_monthly_trends
    @monthly_stats = []
    6.downto(0) do |months_ago|
      date = months_ago.months.ago
      month_start = date.beginning_of_month
      month_end = date.end_of_month

      licenses_bought = @organization.licenses
                                    .where("created_at BETWEEN ? AND ?", month_start, month_end)
                                    .count

      enrollments_created = Enrollment.joins(:user)
                                      .where(users: { organization_id: @organization.id })
                                      .where("enrollments.created_at BETWEEN ? AND ?", month_start, month_end)
                                      .count

      @monthly_stats << {
        month: month_start.strftime("%b %Y"),
        licenses: licenses_bought,
        enrollments: enrollments_created
      }
    end
  end

  def calculate_avg_completion
    return 0 if @employees.empty?

    total = @employees.sum do |emp|
      enrollments = emp.enrollments
      next 0 if enrollments.empty?

      completed = enrollments.where(status: :completed).count
      completed.to_f / enrollments.count * 100
    end

    (total / @employees.count).round(1)
  end

  def calculate_compliance_rate
    return 0 if @employees.empty?

    compliant = @employees.count do |emp|
      emp.enrollments.any? { |e| e.status == :completed }
    end

    (compliant.to_f / @employees.count * 100).round(1)
  end
end
