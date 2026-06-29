module Learning
  # Tạo dữ liệu demo cho personalization dựa trên hành vi học tập và study plan.
  class BehaviorDemoDataBuilder
    Result = Struct.new(:user, :course, :study_plan, :profile, :risk, :focus_items,
                        :plan_suggestions, keyword_init: true)

    DEFAULT_EMAIL = "behavior.demo@example.com"
    DEFAULT_PASSWORD = "Demo@123456"

    def initialize(email: nil, course_id: nil)
      @email = email.presence || DEFAULT_EMAIL
      @course_id = course_id.presence
    end

    def call
      ActiveRecord::Base.transaction do
        course = resolve_course
        user = demo_user
        enroll_user!(user, course)
        plan = demo_study_plan(user, course)

        prepare_plan_items!(plan)
        prepare_progress!(user, course, plan)
        prepare_learning_activities!(user, course, plan)

        profile = Learning::BehaviorProfileBuilder.new(
          user,
          course: course,
          study_plan: plan
        ).call
        risk = Learning::StudyRiskDetector.new(profile).call
        focus_items = Learning::StudyFocusRecommender.new(profile).call
        plan_suggestions = Learning::StudyPlanOptimizer.new(profile, risk: risk).call

        Result.new(
          user: user,
          course: course,
          study_plan: plan,
          profile: profile,
          risk: risk,
          focus_items: focus_items,
          plan_suggestions: plan_suggestions
        )
      end
    end

    private

    attr_reader :email, :course_id

    def resolve_course
      return Course.find(course_id) if course_id

      Course.published.joins(course_modules: :lessons)
            .distinct
            .order(:id)
            .first || raise(ActiveRecord::RecordNotFound, "No published course with lessons found")
    end

    def demo_user
      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.name = "Behavior Demo Learner"
        user.role = :student
        user.password = DEFAULT_PASSWORD
        user.password_confirmation = DEFAULT_PASSWORD
        user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
      end
      user.save!
      user
    end

    def enroll_user!(user, course)
      enrollment = Enrollment.find_or_initialize_by(user: user, course: course)
      enrollment.status = :active
      enrollment.save!
    end

    def demo_study_plan(user, course)
      plan = StudyPlanService.create_plan(
        user: user,
        course: course,
        goal_deadline: 10.days.from_now.to_date,
        preferred_study_times: {
          "monday" => ["19:00-20:00"],
          "wednesday" => ["19:00-20:00"],
          "saturday" => ["09:00-10:00"]
        }
      )
      plan.update!(goal_deadline: 10.days.from_now.to_date)
      plan
    end

    def prepare_plan_items!(plan)
      items = plan.study_plan_items.order(:order_in_course).limit(8).to_a
      raise ActiveRecord::RecordNotFound, "Demo course needs at least 4 study plan items" if items.size < 4

      update_item!(items[0], :completed, 8.days.ago.to_date, actual_completed_at: 7.days.ago)
      update_item!(items[1], :completed, 6.days.ago.to_date, actual_completed_at: 5.days.ago)
      update_item!(items[2], :in_progress, 4.days.ago.to_date)
      update_item!(items[3], :pending, 3.days.ago.to_date)
      update_item!(items[4], :skipped, 2.days.ago.to_date) if items[4]
      update_item!(items[5], :pending, Date.current) if items[5]
      update_item!(items[6], :pending, 1.day.from_now.to_date) if items[6]
      update_item!(items[7], :pending, 2.days.from_now.to_date) if items[7]
    end

    def update_item!(item, status, scheduled_date, actual_completed_at: nil)
      item.update!(
        status: status,
        scheduled_date: scheduled_date,
        actual_completed_at: actual_completed_at,
        is_replan_needed: status.in?(%i[pending skipped]) && scheduled_date < Date.current
      )
    end

    def prepare_progress!(user, course, plan)
      plan.study_plan_items.includes(:lesson).each do |item|
        progress = ProgressTracking.find_or_initialize_by(user: user, lesson: item.lesson)
        progress.course = course
        progress.progress_type = "lesson"
        progress.status = progress_status_for(item)
        progress.progress_value = progress_value_for(item)
        progress.save!
      end
    end

    def progress_status_for(item)
      return "completed" if item.completed?
      return "in_progress" if item.in_progress?

      "not_started"
    end

    def progress_value_for(item)
      return 100 if item.completed?
      return 45 if item.in_progress?

      0
    end

    def prepare_learning_activities!(user, course, plan)
      user.learning_activities.where(course: course)
          .where("activity_date >= ?", 14.days.ago.to_date)
          .delete_all

      completed_items = plan.study_plan_items.completed.includes(:lesson).order(:scheduled_date)
      completed_items.each_with_index do |item, index|
        create_activity!(
          user,
          course,
          item.lesson,
          "lesson_complete",
          activity_date: (7 - index * 2).days.ago.to_date,
          duration_seconds: 24.minutes.to_i
        )
      end

      in_progress = plan.study_plan_items.where(status: "in_progress").includes(:lesson).first
      return unless in_progress

      create_activity!(
        user,
        course,
        in_progress.lesson,
        "lesson_view",
        activity_date: 4.days.ago.to_date,
        duration_seconds: 18.minutes.to_i
      )
    end

    def create_activity!(user, course, lesson, activity_type, activity_date:, duration_seconds:)
      user.learning_activities.create!(
        course: course,
        lesson: lesson,
        activity_type: activity_type,
        activity_date: activity_date,
        duration_seconds: duration_seconds
      )
    end
  end
end
