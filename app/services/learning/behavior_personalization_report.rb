module Learning
  # Tổng hợp pipeline cá nhân hóa dựa trên hành vi học tập để admin giám sát và demo.
  class BehaviorPersonalizationReport
    Report = Struct.new(
      :learners,
      :selected_user,
      :courses,
      :selected_course,
      :study_plan,
      :profile,
      :risk,
      :focus_items,
      :plan_suggestions,
      :recent_activities,
      :summary,
      keyword_init: true
    )

    def initialize(user_id: nil, course_id: nil)
      @user_id = user_id
      @course_id = course_id
    end

    def call
      selected_user = resolve_user
      courses = selected_user ? learner_courses(selected_user) : Course.none
      selected_course = resolve_course(courses)
      plan = selected_user && selected_course ? study_plan(selected_user, selected_course) : nil
      profile = selected_user ? build_profile(selected_user, selected_course, plan) : nil
      risk = profile ? StudyRiskDetector.new(profile).call : nil
      focus_items = profile ? StudyFocusRecommender.new(profile).call(limit: 6) : []
      plan_suggestions = profile ? StudyPlanOptimizer.new(profile, risk: risk).call(limit: 6) : []

      Report.new(
        learners: learners,
        selected_user: selected_user,
        courses: courses,
        selected_course: selected_course,
        study_plan: plan,
        profile: profile,
        risk: risk,
        focus_items: focus_items,
        plan_suggestions: plan_suggestions,
        recent_activities: recent_activities(selected_user, selected_course),
        summary: summary_for(profile, risk, focus_items, plan_suggestions)
      )
    end

    private

    attr_reader :user_id, :course_id

    def learners
      @learners ||= User.joins(:study_plans).distinct.order(:name)
    end

    def resolve_user
      return learners.first if user_id.blank?

      learners.find_by(id: user_id) || learners.first
    end

    def learner_courses(user)
      Course.where(id: user.study_plans.select(:course_id)).order(:title)
    end

    def resolve_course(courses)
      return nil if courses.blank?
      return courses.find_by(id: course_id) || courses.first if course_id.present?

      courses.first
    end

    def study_plan(user, course)
      user.study_plans.where(course: course)
          .order(Arel.sql("CASE status WHEN 'active' THEN 0 ELSE 1 END"), updated_at: :desc)
          .first
    end

    def build_profile(user, course, plan)
      BehaviorProfileBuilder.new(user, course: course, study_plan: plan).call
    end

    def recent_activities(user, course)
      return [] unless user

      scope = user.learning_activities.includes(:course, :lesson)
                  .order(activity_date: :desc, updated_at: :desc)
      scope = scope.where(course: course) if course
      scope.limit(8)
    end

    def summary_for(profile, risk, focus_items, plan_suggestions)
      return empty_summary unless profile

      {
        risk_label: risk&.label || "Unknown",
        risk_score: risk&.score.to_i,
        active_days: profile.active_days,
        inactive_days: profile.inactive_days,
        overdue_items: profile.overdue_items_count,
        skipped_items: profile.skipped_items_count,
        focus_items: focus_items.size,
        plan_suggestions: plan_suggestions.size
      }
    end

    def empty_summary
      {
        risk_label: "Unknown",
        risk_score: 0,
        active_days: 0,
        inactive_days: nil,
        overdue_items: 0,
        skipped_items: 0,
        focus_items: 0,
        plan_suggestions: 0
      }
    end
  end
end
