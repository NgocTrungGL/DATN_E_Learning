class Business::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @organization = current_user.organization

    if @organization.nil?
      redirect_to root_path,
                  alert: "Bạn chưa được liên kết với doanh nghiệp nào"
      return
    end

    # License Stats
    @license_stats = {
      total: @organization.licenses.count,
      assigned: @organization.licenses.where(status: :assigned).count,
      available: @organization.licenses.where(status: :available).count,
      expiring_soon: @organization.licenses.where("expires_at IS NOT NULL AND expires_at <= ? AND expires_at > ?", 7.days.from_now, Time.current).count,
      expired: @organization.licenses.where(status: :expired).count
    }

    # Employee Progress Stats (role: student in org are employees)
    @employees = @organization.users.where(role: :student)
    @employee_stats = {
      total: @employees.count,
      active: @employees.joins(:enrollments).distinct.count(:id),
      completed_courses: Enrollment.joins(:user).where(users: { organization_id: @organization.id, role: :student }).where(status: :completed).count,
      in_progress: @employees.count - @employees.where.missing(:enrollments).count
    }

    # Training ROI
    @total_spent = @organization.licenses.sum(:price).to_f
    @avg_completion_rate = calculate_avg_completion_rate
    @training_cost_per_employee = @employees.count.positive? ? (@total_spent / @employees.count) : 0

    # Monthly enrollment trend (without group_by_month due to MySQL timezone issue)
    @monthly_enrollments = {}

    @top_courses = build_top_course_stats
  end

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path,
                alert: "Bạn không có quyền truy cập khu vực Doanh nghiệp."
  end

  def calculate_avg_completion_rate
    return 0 if @employees.empty?

    total_progress = @employees.sum do |u|
      courses = u.enrollments.pluck(:course_id)
      next 0 if courses.empty?

      completed = ProgressTracking.where(user: u, status: :completed)
                                  .where(course_id: courses).distinct.count(:course_id)
      completed.to_f / courses.count * 100
    end

    (total_progress / @employees.count).round(1)
  end

  def build_top_course_stats
    Course.joins(:licenses)
          .where(licenses: { organization_id: @organization.id })
          .select("courses.*, COUNT(licenses.id) AS licenses_count")
          .group("courses.id")
          .order(Arel.sql("COUNT(licenses.id) DESC"))
          .limit(5)
          .map do |course|
            assigned = @organization.licenses.where(course:, status: :assigned).count
            completed = completed_enrollments_for(course)

            {
              course:,
              assigned:,
              completed:,
              completion_rate: assigned.positive? ? (completed.to_f / assigned * 100).round : 0
            }
          end
  end

  def completed_enrollments_for course
    Enrollment.joins(:user)
              .where(users: { organization_id: @organization.id, role: :student })
              .where(course:, status: :completed)
              .count
  end
end
