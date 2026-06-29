class Student::DashboardController < Student::BaseController
  def show
    @user = current_user
    @streak = @user.learning_streak_record
    GoalProgressService.update_user_goals(@user)
    @active_goal = @user.active_goal

    today = Date.current
    week_start = 1.week.ago.to_date

    @today_seconds = @user.total_study_seconds(from_date: today, to_date: today)
    @week_seconds = @user.total_study_seconds(from_date: week_start, to_date: today)
    @avg_per_day = @week_seconds / 7

    @lessons_today = @user.lesson_completions_count(from_date: today, to_date: today)
    @lessons_week = @user.lesson_completions_count(from_date: week_start, to_date: today)

    @weekly_active_days = @streak.weekly_activity_days

    @weekly_progress_chart = build_weekly_progress_chart
    @daily_study_chart = build_daily_study_chart

    @active_courses = @user.enrollments.active
                           .joins(:course)
                           .includes(course: [:category, :creator, { course_modules: :lessons }])
                           .limit(3)
    @recommended_results = recommended_course_results(limit: 4)

    @active_study_plan = @user.study_plans.active.includes(:course).first
    @todays_lessons = @active_study_plan&.study_plan_items
                                         &.pending
                                         &.where(scheduled_date: Date.today)
    load_behavior_personalization
  end

  private

  def load_behavior_personalization
    return unless @active_study_plan

    @behavior_profile = Learning::BehaviorProfileBuilder.new(
      @user,
      course: @active_study_plan.course,
      study_plan: @active_study_plan
    ).call
    @study_risk = Learning::StudyRiskDetector.new(@behavior_profile).call
    @focus_recommendations = Learning::StudyFocusRecommender.new(
      @behavior_profile
    ).call(limit: 4)
    @plan_suggestions = Learning::StudyPlanOptimizer.new(
      @behavior_profile,
      risk: @study_risk
    ).call(limit: 3)
  end

  def build_weekly_progress_chart
    (0..11).map do |week_offset|
      week_end = 1.week.ago.to_date - week_offset.weeks
      week_start = week_end - 6.days
      completions = @user.lesson_completions_count(from_date: week_start, to_date: week_end)
      {
        week_start.strftime("%d/%m") => completions
      }
    end.reverse.inject(:merge) || {}
  end

  def build_daily_study_chart
    (0..6).map do |day_offset|
      date = Date.current - day_offset.days
      seconds = @user.total_study_seconds(from_date: date, to_date: date)
      {
        date.strftime("%d/%m") => (seconds / 3600.0).round(1)
      }
    end.reverse.inject(:merge) || {}
  end
end
