class StudyPlanAdjustment < ApplicationRecord
  belongs_to :study_plan

  VALID_REASONS = %w[
    late_completion
    student_request
    goal_changed
    system_replan
  ].freeze

  validates :reason, presence: true, inclusion: { in: VALID_REASONS }
  validates :old_target_date, presence: true
  validates :new_target_date, presence: true

  def self.create_for!(plan, reason, replanned_items: [])
    old_date = plan.goal_deadline
    new_date = calculate_new_deadline(plan, reason)

    adjustment = create!(
      study_plan: plan,
      reason: reason,
      old_target_date: old_date,
      new_target_date: new_date,
      replanned_items: replanned_items.map { |item| item.id }
    )

    plan.update!(goal_deadline: new_date)
    adjustment
  end

  def self.calculate_new_deadline(plan, reason)
    case reason
    when "late_completion"
      # Extend deadline by number of delayed days + 1 buffer day
      delay_days = plan.overdue_items.count
      plan.goal_deadline + delay_days + 1
    when "system_replan"
      # Extend by 20% of remaining days
      remaining_days = (plan.goal_deadline - Date.today).to_i
      Date.today + (remaining_days * 1.2).to_i
    else
      plan.goal_deadline
    end
  end
end
