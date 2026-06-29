module Learning
  # Đề xuất tối ưu lịch học dựa trên rủi ro và hành vi, chưa tự thay đổi plan.
  class StudyPlanOptimizer
    Suggestion = Struct.new(
      :kind,
      :title,
      :description,
      :priority,
      :study_plan_item_ids,
      :metadata,
      keyword_init: true
    )

    def initialize(profile, risk: nil)
      @profile = profile
      @risk = risk || StudyRiskDetector.new(profile).call
    end

    def call(limit: 4)
      return [] unless profile.study_plan

      suggestions.compact.sort_by { |suggestion| -suggestion.priority }.first(limit)
    end

    private

    attr_reader :profile, :risk

    def suggestions
      [
        catch_up_session,
        extend_deadline,
        reduce_daily_load,
        restart_session
      ]
    end

    def catch_up_session
      overdue_items = profile.study_plan.overdue_items.limit(3)
      return if overdue_items.empty?

      Suggestion.new(
        kind: :catch_up_session,
        title: "Add a catch-up session",
        description: "Prioritize overdue lessons before adding new workload.",
        priority: 95,
        study_plan_item_ids: overdue_items.pluck(:id),
        metadata: { overdue_count: profile.overdue_items_count }
      )
    end

    def extend_deadline
      plan = profile.study_plan
      return unless plan.goal_deadline
      return unless risk.level.in?(%i[at_risk behind])

      delay_days = [profile.overdue_items_count.to_i, 1].max
      Suggestion.new(
        kind: :extend_deadline,
        title: "Extend the study deadline",
        description: "Move the goal deadline by #{delay_days + 1} days to match the current pace.",
        priority: 80,
        study_plan_item_ids: [],
        metadata: {
          old_deadline: plan.goal_deadline,
          suggested_deadline: plan.goal_deadline + delay_days + 1
        }
      )
    end

    def reduce_daily_load
      required = profile.required_daily_minutes.to_i
      capacity = profile.daily_capacity_minutes.to_i
      return if required.zero? || capacity.zero? || required <= capacity * 1.15

      Suggestion.new(
        kind: :reduce_daily_load,
        title: "Reduce daily workload",
        description: "The current plan needs #{required} minutes/day while the observed pace is #{capacity} minutes/day.",
        priority: 70,
        study_plan_item_ids: [],
        metadata: { required_daily_minutes: required, daily_capacity_minutes: capacity }
      )
    end

    def restart_session
      days = profile.inactive_days
      return unless days && days >= 3

      Suggestion.new(
        kind: :restart_session,
        title: "Start a short restart session",
        description: "The learner has been inactive for #{days} days.",
        priority: 60,
        study_plan_item_ids: [],
        metadata: { inactive_days: days }
      )
    end
  end
end
