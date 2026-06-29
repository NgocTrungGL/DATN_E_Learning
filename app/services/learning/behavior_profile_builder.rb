module Learning
  # Xây hồ sơ hành vi học tập từ activity, progress và study plan thay vì quiz/skill.
  class BehaviorProfileBuilder
    Profile = Struct.new(
      :user,
      :course,
      :study_plan,
      :from_date,
      :to_date,
      :active_days,
      :total_study_minutes,
      :avg_study_minutes_per_active_day,
      :avg_study_minutes_per_calendar_day,
      :lesson_views_count,
      :completed_lessons_count,
      :course_progress_percentage,
      :plan_progress_percentage,
      :total_plan_items_count,
      :completed_plan_items_count,
      :pending_items_count,
      :overdue_items_count,
      :skipped_items_count,
      :in_progress_items_count,
      :last_activity_at,
      :inactive_days,
      :daily_capacity_minutes,
      :required_daily_minutes,
      :remaining_plan_minutes,
      keyword_init: true
    )

    DEFAULT_WINDOW_DAYS = 30
    DEFAULT_DAILY_CAPACITY_MINUTES = 45

    def initialize(user, course: nil, study_plan: nil, window_days: DEFAULT_WINDOW_DAYS)
      @user = user
      @course = course
      @study_plan = study_plan || resolve_study_plan
      @from_date = window_days.days.ago.to_date
      @to_date = Date.current
    end

    def call
      Profile.new(
        user: user,
        course: course,
        study_plan: study_plan,
        from_date: from_date,
        to_date: to_date,
        active_days: active_days,
        total_study_minutes: total_study_minutes,
        avg_study_minutes_per_active_day: average_per_active_day,
        avg_study_minutes_per_calendar_day: average_per_calendar_day,
        lesson_views_count: lesson_views_count,
        completed_lessons_count: completed_lessons_count,
        course_progress_percentage: course_progress_percentage,
        plan_progress_percentage: plan_progress_percentage,
        total_plan_items_count: total_plan_items_count,
        completed_plan_items_count: completed_plan_items_count,
        pending_items_count: pending_items_count,
        overdue_items_count: overdue_items_count,
        skipped_items_count: skipped_items_count,
        in_progress_items_count: in_progress_items_count,
        last_activity_at: last_activity&.updated_at,
        inactive_days: inactive_days,
        daily_capacity_minutes: daily_capacity_minutes,
        required_daily_minutes: required_daily_minutes,
        remaining_plan_minutes: remaining_plan_minutes
      )
    end

    private

    attr_reader :user, :course, :study_plan, :from_date, :to_date

    def resolve_study_plan
      scope = user.study_plans.active
      scope = scope.where(course: course) if course
      scope.order(updated_at: :desc).first
    end

    def activities
      @activities ||= begin
        scope = user.learning_activities.where(activity_date: from_date..to_date)
        scope = scope.where(course: course) if course
        scope
      end
    end

    def progress_trackings
      @progress_trackings ||= begin
        scope = user.progress_trackings
        scope = scope.where(course: course) if course
        scope
      end
    end

    def plan_items
      @plan_items ||= study_plan ? study_plan.study_plan_items.includes(:lesson) : StudyPlanItem.none
    end

    def active_days
      @active_days ||= activities.select(:activity_date).distinct.count
    end

    def total_study_minutes
      @total_study_minutes ||= (activities.sum(:duration_seconds).to_i / 60.0).round
    end

    def average_per_active_day
      return 0 if active_days.zero?

      (total_study_minutes.to_f / active_days).round
    end

    def average_per_calendar_day
      days = [(to_date - from_date).to_i + 1, 1].max

      (total_study_minutes.to_f / days).round
    end

    def lesson_views_count
      activities.where(activity_type: "lesson_view").count
    end

    def completed_lessons_count
      progress_trackings.lesson.completed.where.not(lesson_id: nil).count
    end

    def course_progress_percentage
      return study_plan.progress_percentage if study_plan
      return 0 unless course

      lesson_count = course.lessons.count
      return 0 if lesson_count.zero?

      (completed_lessons_count.to_f / lesson_count * 100).round
    end

    def plan_progress_percentage
      study_plan ? study_plan.progress_percentage : 0
    end

    def total_plan_items_count
      plan_items.count
    end

    def completed_plan_items_count
      plan_items.completed.count
    end

    def pending_items_count
      plan_items.pending.count
    end

    def overdue_items_count
      plan_items.overdue.count
    end

    def skipped_items_count
      plan_items.where(status: "skipped").count
    end

    def in_progress_items_count
      plan_items.where(status: "in_progress").count
    end

    def last_activity
      @last_activity ||= activities.order(activity_date: :desc, updated_at: :desc).first
    end

    def inactive_days
      return nil unless last_activity

      (Date.current - last_activity.activity_date).to_i
    end

    def daily_capacity_minutes
      observed = average_per_active_day
      return DEFAULT_DAILY_CAPACITY_MINUTES if observed.zero?

      observed.clamp(15, 180)
    end

    def required_daily_minutes
      return 0 unless study_plan&.goal_deadline

      remaining_days = [(study_plan.goal_deadline - Date.current).to_i, 1].max
      (remaining_plan_minutes.to_f / remaining_days).round
    end

    def remaining_plan_minutes
      plan_items.where(status: %w[pending in_progress])
                .sum(:estimated_duration_minutes)
                .to_i
    end
  end
end
