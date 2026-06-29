class StudyPlanReminderJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    # Get all active study plans
    active_plans = StudyPlan.active
                            .includes(:user, :course, :study_plan_items)
                            .where("goal_deadline >= ?", date)

    active_plans.find_each do |plan|
      send_reminders_for_plan(plan, date)
    end
  end

  private

  def send_reminders_for_plan(plan, date)
    user = plan.user

    # Check for today's lessons
    todays_items = plan.study_plan_items
                       .pending
                       .where(scheduled_date: date)

    if todays_items.any?
      create_daily_reminder(plan, user, todays_items)
    end

    # Check for overdue items
    overdue_items = plan.overdue_items
    if overdue_items.any?
      create_overdue_reminder(plan, user, overdue_items)
      # Auto-adjust plan for moderate or severe cases
      StudyPlanService.auto_adjust_plan(plan)
    end

    # Check for deadline approaching (3 days or less)
    days_remaining = plan.days_remaining
    if days_remaining <= 3 && days_remaining > 0
      create_deadline_reminder(plan, user, days_remaining)
    end
  end

  def create_daily_reminder(plan, user, items)
    lesson_titles = items.take(3).map { |item| item.lesson.title }.join(", ")
    more_count = items.count - 3

    body = if more_count.positive?
             "Ban co #{items.count} bai hoc can hoan thanh hom nay: #{lesson_titles}, va #{more_count} bai khac."
           else
             "Ban co #{items.count} bai hoc can hoan thanh hom nay: #{lesson_titles}."
           end

    Notification.create!(
      user: user,
      title: "Lich hoc hom nay - #{plan.course.title}",
      body: body,
      notification_type: :study_plan_reminder,
      actionable: plan
    )
  end

  def create_overdue_reminder(plan, user, items)
    Notification.create!(
      user: user,
      title: "Ban dang tre len lich!",
      body: "Ban co #{items.count} bai hoc dang tre. Lich hoc da duoc tu dong dieu chinh.",
      notification_type: :study_plan_reminder,
      actionable: plan
    )
  end

  def create_deadline_reminder(plan, user, days_remaining)
    Notification.create!(
      user: user,
      title: "Han hoan thanh gan den!",
      body: "Con #{days_remaining} ngay nua la den han hoan thanh khoa hoc '#{plan.course.title}'. " \
            "Ban da hoan thanh #{plan.progress_percentage}%.",
      notification_type: :study_plan_reminder,
      actionable: plan
    )
  end
end
