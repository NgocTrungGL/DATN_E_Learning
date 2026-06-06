class StudyPlan < ApplicationRecord
  belongs_to :user
  belongs_to :course
  has_many :study_plan_items, dependent: :destroy
  has_many :study_plan_adjustments, dependent: :destroy

  enum status: { active: "active", completed: "completed", paused: "paused", cancelled: "cancelled" }

  scope :active_plans, ->(user) { where(user_id: user.id, status: :active) }
  scope :for_course, ->(user, course) { where(user_id: user.id, course_id: course.id) }

  def overdue_items
    study_plan_items.where("scheduled_date < ?", Date.today).pending
  end

  def completed_items
    study_plan_items.completed
  end

  def pending_items
    study_plan_items.pending
  end

  def progress_percentage
    return 0 if study_plan_items.count.zero?

    (completed_items.count.to_f / study_plan_items.count * 100).round
  end

  def days_remaining
    return 0 if goal_deadline.blank?

    (goal_deadline - Date.today).to_i
  end

  def estimated_completion_date
    return goal_deadline if goal_deadline.present?

    # Calculate based on average completion rate
    return nil if study_plan_items.count.zero?

    completed_count = completed_items.count
    total_count = study_plan_items.count
    days_taken = completed_count.positive? ? (Date.today - started_at.to_date).to_i : 0

    return started_at.to_date + total_count if days_taken.zero?

    avg_days_per_item = days_taken.to_f / completed_count
    Date.today + (total_count - completed_count) * avg_days_per_item
  end
end
