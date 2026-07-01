class StudyPlanService
  ANALYSIS_DAYS = 30
  DEFAULT_DAILY_HOURS = 1.5
  DEFAULT_LESSON_MINUTES = 15
  QUIZ_MINUTES_PER_QUESTION = 2
  BUFFER_FACTOR = 1.2
  MAX_DAILY_WORKLOAD_MINUTES = 8 * 60

  PlanValidationError = Class.new(StandardError)

  class << self
    def create_plan(user:, course:, goal_deadline:, preferred_study_times: {})
      ActiveRecord::Base.transaction do
        validate_plan_request!(user, course, preferred_study_times:)

        existing_plan = StudyPlan.for_course(user, course).active.first
        return existing_plan if existing_plan.present?

        # Reactivate paused/cancelled plan if exists, otherwise create new
        inactive_plan = StudyPlan.for_course(user, course)
                                 .where(status: [:paused, :cancelled]).first

        if inactive_plan
          profile = learning_profile(user)
          lessons = remaining_lessons(user, course)
          return nil if lessons.empty?

          daily_capacity = calculate_daily_capacity(user, profile)
          deadline = goal_deadline || suggest_deadline(user, course, preferred_days: profile[:preferred_days])

          inactive_plan.update!(
            status: :active,
            goal_deadline: deadline,
            preferred_study_times: preferred_study_times,
            started_at: Time.current,
            target_days: calculate_target_days(
              lessons.sum { |lesson| estimate_lesson_duration(user, lesson) },
              daily_capacity
            )
          )
          inactive_plan.study_plan_items.destroy_all
          schedule_lessons(inactive_plan, lessons,
                           preferred_times: preferred_study_times,
                           daily_capacity: daily_capacity,
                           profile: profile)
          validate_scheduled_plan!(inactive_plan)
          return inactive_plan
        end

        # No plan exists — create from scratch
        profile = learning_profile(user)
        lessons = remaining_lessons(user, course)
        return nil if lessons.empty?

        daily_capacity = calculate_daily_capacity(user, profile)
        total_minutes = lessons.sum { |lesson| estimate_lesson_duration(user, lesson) }
        deadline = goal_deadline || suggest_deadline(user, course, preferred_days: profile[:preferred_days])

        plan = StudyPlan.create!(
          user: user,
          course: course,
          goal_deadline: deadline,
          target_days: calculate_target_days(total_minutes, daily_capacity),
          preferred_study_times: preferred_study_times,
          status: :active,
          started_at: Time.current
        )

        schedule_lessons(plan, lessons,
                         preferred_times: preferred_study_times,
                         daily_capacity: daily_capacity,
                         profile: profile)
        validate_scheduled_plan!(plan)

        plan
      end
    end

    def learning_profile(user)
      recent_date = ANALYSIS_DAYS.days.ago.to_date

      # Get learning activities from last 30 days
      activities = user.learning_activities.where("activity_date >= ?", recent_date)

      # Calculate average lessons per day
      total_lessons = activities.lesson_completions
                                .where.not(lesson_id: nil)
                                .distinct
                                .count(:lesson_id)
      active_days = activities.select(:activity_date).distinct.count
      avg_lessons_per_day = active_days.positive? ? (total_lessons.to_f / active_days) : 0

      # Calculate average hours per day
      total_seconds = activities.sum(:duration_seconds)
      avg_hours_per_day = active_days.positive? ? (total_seconds.to_f / active_days / 3600) : DEFAULT_DAILY_HOURS

      # Calculate preferred study days (Date#wday: 0=Sunday, 1=Monday, etc.)
      preferred_days = calculate_preferred_days(activities)

      # Calculate average lesson duration
      lesson_activities = activities.where(activity_type: [:lesson_view, :lesson_complete])
      avg_lesson_duration = lesson_activities.any? ?
        (lesson_activities.sum(:duration_seconds).to_f / lesson_activities.count) : DEFAULT_LESSON_MINUTES * 60

      # Calculate quiz score average
      quiz_score_avg = user.quiz_attempts.completed
                          .where("finished_at >= ?", recent_date)
                          .average(:score)&.round || 0

      # Get learning streak info
      streak = user.learning_streak
      has_active_streak = streak.present? && streak.current_streak.positive?

      {
        avg_lessons_per_day: avg_lessons_per_day,
        avg_hours_per_day: avg_hours_per_day,
        preferred_days: preferred_days,
        avg_lesson_duration: avg_lesson_duration,
        quiz_score_avg: quiz_score_avg,
        has_active_streak: has_active_streak,
        current_streak: streak&.current_streak || 0
      }
    end

    def learning_speed(user, course)
      profile = learning_profile(user)
      daily_capacity = calculate_daily_capacity(user, profile)

      {
        lessons_per_day: profile[:avg_lessons_per_day].round(2),
        hours_per_day: profile[:avg_hours_per_day].round(2),
        daily_capacity_minutes: daily_capacity.round,
        avg_lesson_duration_seconds: profile[:avg_lesson_duration].round
      }
    end

    def schedule_lessons(plan, lessons = nil, preferred_times: {}, daily_capacity: nil, profile: nil)
      lessons ||= remaining_lessons(plan.user, plan.course)
      return plan if lessons.empty?

      profile ||= learning_profile(plan.user)
      daily_capacity ||= calculate_daily_capacity(plan.user, profile)
      if preferred_times.blank?
        preferred_times = plan.preferred_study_times || {}
      end

      # Group lessons by module to keep them together
      module_groups = lessons.group_by(&:course_module_id)

      scheduled_date = next_available_date(Date.today, preferred_times, profile)
      current_day_minutes = 0
      order_index = 0

      module_groups.each do |_module_id, module_lessons|
        module_lessons.each do |lesson|
          estimated_minutes = estimate_lesson_duration(plan.user, lesson)

          # Add quiz time if lesson has quiz
          quiz_minutes = estimate_quiz_duration(lesson)

          # Check if we need to move to next day
          total_item_minutes = estimated_minutes + quiz_minutes

          if current_day_minutes.positive? &&
             current_day_minutes + total_item_minutes > daily_capacity
            scheduled_date = next_available_date(scheduled_date + 1, preferred_times, profile)
            current_day_minutes = 0
          end

          # Create study plan item
          start_time = determine_start_time(scheduled_date, preferred_times, current_day_minutes)

          StudyPlanItem.create!(
            study_plan: plan,
            lesson: lesson,
            scheduled_date: scheduled_date,
            scheduled_start_time: start_time,
            estimated_duration_minutes: estimated_minutes + quiz_minutes,
            order_in_course: order_index,
            status: :pending,
            is_replan_needed: false
          )

          order_index += 1
          current_day_minutes += total_item_minutes
        end
      end

      plan
    end

    def estimate_lesson_duration(user, lesson)
      return DEFAULT_LESSON_MINUTES unless lesson.present?

      # Use cached duration if available (video lessons)
      if lesson.cached_duration_seconds.present? && lesson.cached_duration_seconds.positive?
        video_minutes = (lesson.cached_duration_seconds.to_f / 60).ceil

        # Adjust based on user's learning speed
        profile = learning_profile(user)
        speed_factor = calculate_speed_factor(profile)

        # Add 20% for text content processing time
        adjusted_minutes = lesson.text? ? (video_minutes * 1.2).ceil : video_minutes

        (adjusted_minutes * speed_factor).ceil
      else
        # Default estimate for lessons without cached duration
        lesson.text? ? DEFAULT_LESSON_MINUTES * 2 : DEFAULT_LESSON_MINUTES
      end
    end

    def auto_adjust_plan(plan)
      return plan unless plan.active?

      overdue_items = plan.overdue_items
      return plan if overdue_items.empty?

      # Calculate delay severity
      delay_days = (Date.today - overdue_items.minimum(:scheduled_date)).to_i
      completion_rate = plan.progress_percentage

      severity = determine_severity(delay_days, completion_rate)

      case severity
      when :light
        adjust_light(plan, overdue_items)
      when :moderate
        adjust_moderate(plan, overdue_items, delay_days)
      when :severe
        adjust_severe(plan, overdue_items, delay_days)
      end

      plan.reload
    end

    def feasibility_check(plan)
      remaining_items = plan.pending_items
      remaining_days = plan.days_remaining
      profile = learning_profile(plan.user)

      return { feasible: false, reason: :no_deadline } if remaining_days <= 0

      remaining_minutes = remaining_items.sum(:estimated_duration_minutes)
      required_per_day = remaining_minutes.to_f / remaining_days
      daily_capacity = calculate_daily_capacity(plan.user, profile)

      feasible = required_per_day <= daily_capacity * 1.5
      required_days = (remaining_minutes.to_f / daily_capacity).ceil
      suggested_deadline = Date.current + required_days unless feasible

      {
        feasible: feasible,
        required_per_day: required_per_day.round(2),
        daily_capacity: daily_capacity,
        remaining_items: remaining_items.count,
        remaining_days: remaining_days,
        suggested_deadline: suggested_deadline,
        reason: feasible ? nil : :overloaded
      }
    end

    def suggest_deadline(user, course, preferred_days: nil)
      profile = learning_profile(user)
      preferred_days ||= profile[:preferred_days]

      lessons = remaining_lessons(user, course)
      return Date.today + 30 if lessons.empty?

      total_minutes = lessons.sum { |lesson| estimate_lesson_duration(user, lesson) }
      daily_capacity = calculate_daily_capacity(user, profile)

      estimated_study_days = (total_minutes / daily_capacity).ceil

      # Add buffer for rest days
      required_study_days = estimated_study_days +
                            (estimated_study_days * 0.2).ceil
      estimated_deadline = date_after_study_days(
        preferred_days,
        from_date: Date.current,
        study_days: required_study_days
      )

      [estimated_deadline, Date.current + 90].min
    end

    def validate_plan_update!(plan, preferred_study_times:)
      if preferred_time_conflict?(plan.user, preferred_study_times, excluding_plan: plan)
        raise PlanValidationError, "This study time overlaps with another active plan. Please choose a different time slot."
      end
    end

    def validate_scheduled_plan!(plan)
      conflict = scheduled_time_conflict(plan)
      if conflict
        raise PlanValidationError, "This plan conflicts with another active plan on #{conflict.scheduled_date}."
      end

      overloaded_date, total_minutes = overloaded_day(plan)
      return unless overloaded_date

      hours = (total_minutes.to_f / 60).round(1)
      raise PlanValidationError,
            "Your active study plans require #{hours} hours on #{overloaded_date}, which is over the 8-hour daily limit."
    end

    private

    def validate_plan_request!(user, course, preferred_study_times:)
      raise PlanValidationError, "Please choose an available enrolled course." unless course

      if course_completed?(user, course)
        raise PlanValidationError, "This course is already completed, so a new study plan is not needed."
      end

      if remaining_lessons(user, course).empty?
        raise PlanValidationError, "All lessons in this course are already completed."
      end

      if preferred_time_conflict?(user, preferred_study_times)
        raise PlanValidationError, "This study time overlaps with another active plan. Please choose a different time slot."
      end
    end

    def ordered_lessons(course)
      course.lessons
            .includes(:course_module, :quizzes)
            .joins(:course_module)
            .order("course_modules.order_index ASC", :order_index)
    end

    def remaining_lessons(user, course)
      completed_ids = user.progress_trackings
                          .lesson
                          .completed
                          .where(course: course)
                          .where.not(lesson_id: nil)
                          .select(:lesson_id)

      ordered_lessons(course).where.not(id: completed_ids)
    end

    def course_completed?(user, course)
      total_lessons = course.lessons.count
      return false if total_lessons.zero?

      completed_lessons = user.progress_trackings
                              .lesson
                              .completed
                              .where(course: course)
                              .where.not(lesson_id: nil)
                              .distinct
                              .count(:lesson_id)

      completed_lessons >= total_lessons || user.course_progress_percentage(course) >= 100
    end

    def preferred_time_conflict?(user, preferred_study_times, excluding_plan: nil)
      new_slots = normalized_weekly_slots(preferred_study_times)
      return false if new_slots.empty?

      user.study_plans.active.includes(:study_plan_items).any? do |plan|
        next false if excluding_plan && plan.id == excluding_plan.id

        existing_slots = normalized_weekly_slots(plan.preferred_study_times)
        slots_overlap?(new_slots, existing_slots)
      end
    end

    def normalized_weekly_slots(preferred_study_times)
      Array(preferred_study_times).flat_map do |day, slots|
        Array(slots).filter_map do |slot|
          start_time, end_time = parse_slot(slot)
          next unless start_time && end_time

          { day: day.to_s, start_time: start_time, end_time: end_time }
        end
      end
    end

    def slots_overlap?(left_slots, right_slots)
      left_slots.any? do |left|
        right_slots.any? do |right|
          left[:day] == right[:day] &&
            intervals_overlap?(left[:start_time], left[:end_time],
                               right[:start_time], right[:end_time])
        end
      end
    end

    def parse_slot(slot)
      start_text, end_text = slot.to_s.split("-", 2).map(&:strip)
      return [nil, nil] if start_text.blank? || end_text.blank?

      start_time = Time.zone.parse(start_text)
      end_time = Time.zone.parse(end_text)
      return [nil, nil] unless start_time && end_time && end_time > start_time

      [start_time, end_time]
    rescue ArgumentError
      [nil, nil]
    end

    def scheduled_time_conflict(plan)
      plan.study_plan_items.includes(study_plan: :user).detect do |item|
        item_interval = scheduled_interval(item)
        next false unless item_interval

        other_active_items(plan, item.scheduled_date).any? do |other_item|
          other_interval = scheduled_interval(other_item)
          other_interval &&
            intervals_overlap?(item_interval.first, item_interval.last,
                               other_interval.first, other_interval.last)
        end
      end
    end

    def other_active_items(plan, scheduled_date)
      StudyPlanItem.joins(:study_plan)
                   .where(study_plans: { user_id: plan.user_id, status: :active })
                   .where.not(study_plan_id: plan.id)
                   .where(scheduled_date: scheduled_date)
    end

    def scheduled_interval(item)
      return unless item.scheduled_date && item.scheduled_start_time

      start_time = Time.zone.local(
        item.scheduled_date.year,
        item.scheduled_date.month,
        item.scheduled_date.day,
        item.scheduled_start_time.hour,
        item.scheduled_start_time.min
      )
      [start_time, start_time + item.estimated_duration_minutes.to_i.minutes]
    end

    def intervals_overlap?(left_start, left_end, right_start, right_end)
      left_start < right_end && right_start < left_end
    end

    def overloaded_day(plan)
      totals = StudyPlanItem.joins(:study_plan)
                            .where(study_plans: { user_id: plan.user_id, status: :active })
                            .group(:scheduled_date)
                            .sum(:estimated_duration_minutes)

      totals.find { |_date, minutes| minutes.to_i > MAX_DAILY_WORKLOAD_MINUTES }
    end

    def calculate_daily_capacity(_user, profile)
      return DEFAULT_DAILY_HOURS * 60 if profile[:avg_hours_per_day].zero?

      # Base capacity from user's average study time
      base_capacity = profile[:avg_hours_per_day] * 60

      # Boost for students with active streaks (they're motivated)
      if profile[:has_active_streak]
        base_capacity *= 1.1
      end

      # Adjust based on quiz performance (better scores = faster learner)
      if profile[:quiz_score_avg] >= 80
        base_capacity *= 1.15
      elsif profile[:quiz_score_avg] < 60
        base_capacity *= 0.85
      end

      [base_capacity.round, 240].min # Cap at 4 hours per day
    end

    def calculate_speed_factor(profile)
      return 1.0 if profile[:avg_lesson_duration].zero?

      # Compare user's average lesson duration to baseline
      baseline_duration = DEFAULT_LESSON_MINUTES * 60
      observed_ratio = profile[:avg_lesson_duration].to_f /
                       baseline_duration
      observed_ratio.clamp(0.5, 2.0)
    end

    def calculate_preferred_days(activities)
      return (0..6).to_a if activities.empty?

      # Count activities by day of week
      day_counts = activities.group(Arel.sql(day_of_week_sql))
                             .count

      # Return all days with activities, sorted by activity count
      day_counts.sort_by { |_day, count| -count }
                .map { |day, _count| day.to_i }
    end

    def day_of_week_sql
      adapter = ActiveRecord::Base.connection_db_config.adapter.downcase

      if adapter.include?("postgres")
        "EXTRACT(DOW FROM activity_date)::integer"
      elsif adapter.include?("mysql")
        "(DAYOFWEEK(activity_date) - 1)"
      else
        "CAST(strftime('%w', activity_date) AS integer)"
      end
    end

    def next_available_date(date, preferred_times, profile)
      max_days_to_search = 14
      search_date = date

      max_days_to_search.times do
        return search_date if is_preferred_day?(search_date, preferred_times, profile)

        search_date += 1
      end

      date
    end

    def is_preferred_day?(date, preferred_times, profile)
      if preferred_times.blank?
        return profile[:preferred_days].blank? ||
               profile[:preferred_days].include?(date.wday)
      end

      day_name = date.strftime("%A").downcase
      time_slots = preferred_times[day_name] ||
                   preferred_times[day_name.to_sym]

      time_slots.is_a?(Array) && time_slots.present?
    end

    def determine_start_time(date, preferred_times, current_minutes)
      day_name = date.strftime("%A").downcase
      time_slots = preferred_times[day_name] ||
                   preferred_times[day_name.to_sym]

      return Time.parse("19:00") if time_slots.blank? || time_slots.empty?

      start_time = if time_slots.is_a?(Array)
                     Time.parse(time_slots.first.split("-").first)
                   else
                     Time.parse("19:00")
                   end
      start_time + current_minutes.minutes
    rescue StandardError
      Time.parse("19:00")
    end

    def estimate_quiz_duration(lesson)
      quiz = lesson.quizzes.first
      return 0 unless quiz.present?

      total_questions = quiz.total_questions || 0

      (total_questions * QUIZ_MINUTES_PER_QUESTION)
    end

    def calculate_target_days(total_minutes, daily_capacity)
      return 1 if daily_capacity.zero?

      (total_minutes.to_f / daily_capacity * BUFFER_FACTOR).ceil
    end

    def determine_severity(delay_days, completion_rate)
      if delay_days < 3 && completion_rate > 50
        :light
      elsif delay_days <= 7
        :moderate
      else
        :severe
      end
    end

    def adjust_light(plan, overdue_items)
      # Move overdue items to end, slightly increase daily load
      max_date = plan.study_plan_items.maximum(:scheduled_date)
      new_date = max_date + 1

      overdue_items.update_all(
        scheduled_date: new_date,
        is_replan_needed: true
      )

      create_adjustment(plan, "late_completion", overdue_items.pluck(:id),
                        old_target_date: plan.goal_deadline,
                        new_target_date: plan.goal_deadline)
    end

    def adjust_moderate(plan, overdue_items, delay_days)
      # Extend deadline and reschedule overdue items
      new_deadline = plan.goal_deadline + delay_days + 1

      max_date = plan.study_plan_items.maximum(:scheduled_date)
      new_date = [max_date + 1, Date.today + 1].max

      overdue_items.update_all(
        scheduled_date: new_date,
        is_replan_needed: true
      )

      old_deadline = plan.goal_deadline
      plan.update!(goal_deadline: new_deadline)

      create_adjustment(plan, "late_completion", overdue_items.pluck(:id),
                        old_target_date: old_deadline,
                        new_target_date: new_deadline)
    end

    def adjust_severe(plan, overdue_items, delay_days)
      # For severe cases, just mark items as needing replan
      # Don't auto-adjust too aggressively
      overdue_items.update_all(is_replan_needed: true)

      create_adjustment(plan, "late_completion", overdue_items.pluck(:id),
                        old_target_date: plan.goal_deadline,
                        new_target_date: plan.goal_deadline)
    end

    def create_adjustment(plan, reason, item_ids, old_target_date:,
                          new_target_date:)
      StudyPlanAdjustment.create!(
        study_plan: plan,
        reason: reason,
        old_target_date: old_target_date,
        new_target_date: new_target_date,
        replanned_items: item_ids
      )
    end

    def date_after_study_days(preferred_days, from_date:, study_days:)
      days = Array(preferred_days).map(&:to_i).uniq
      days = (0..6).to_a if days.empty?

      current = from_date
      remaining = [study_days, 1].max

      while remaining.positive?
        remaining -= 1 if days.include?(current.wday)
        current += 1 if remaining.positive?
      end

      current
    end
  end
end
