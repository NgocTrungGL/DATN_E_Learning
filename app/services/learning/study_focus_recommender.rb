module Learning
  # Chọn việc học nên tập trung hôm nay dựa trên trạng thái study plan thực tế.
  class StudyFocusRecommender
    Recommendation = Struct.new(
      :kind,
      :title,
      :description,
      :lesson,
      :study_plan_item,
      :priority,
      :action_label,
      keyword_init: true
    )

    def initialize(profile)
      @profile = profile
      @study_plan = profile.study_plan
    end

    def call(limit: 5)
      return [] unless study_plan

      recommendations.first(limit)
    end

    private

    attr_reader :profile, :study_plan

    def recommendations
      @recommendations ||= [
        resume_recommendations,
        overdue_recommendations,
        skipped_recommendations,
        today_recommendations,
        next_recommendation
      ].flatten.compact
       .sort_by { |recommendation| [-recommendation.priority, recommendation.study_plan_item&.scheduled_date || Date.current] }
       .uniq { |recommendation| recommendation.study_plan_item&.id || recommendation.title }
    end

    def resume_recommendations
      items.where(status: "in_progress").order(updated_at: :asc).limit(2).map do |item|
        build(:resume, item, 100,
              "Resume #{item.lesson.title}",
              "This lesson is already in progress.",
              "Resume")
      end
    end

    def overdue_recommendations
      items.overdue.order(:scheduled_date, :order_in_course).limit(3).map do |item|
        build(:catch_up, item, 90,
              "Catch up #{item.lesson.title}",
              "Scheduled for #{item.scheduled_date}, now overdue.",
              "Catch up")
      end
    end

    def skipped_recommendations
      items.where(status: "skipped").order(updated_at: :desc).limit(2).map do |item|
        build(:revisit, item, 70,
              "Revisit #{item.lesson.title}",
              "This lesson was skipped and can be reviewed later.",
              "Review")
      end
    end

    def today_recommendations
      items.pending.where(scheduled_date: Date.current)
           .order(:order_in_course)
           .limit(2)
           .map do |item|
        build(:today, item, 60,
              "Continue #{item.lesson.title}",
              "This lesson is scheduled for today.",
              "Start")
      end
    end

    def next_recommendation
      item = items.pending.order(:scheduled_date, :order_in_course).first
      return unless item

      build(:next_lesson, item, 40,
            "Continue #{item.lesson.title}",
            "This is the next lesson in the instructor-defined course order.",
            "Continue")
    end

    def items
      @items ||= study_plan.study_plan_items.includes(:lesson)
    end

    def build(kind, item, priority, title, description, action_label)
      Recommendation.new(
        kind: kind,
        title: title,
        description: description,
        lesson: item.lesson,
        study_plan_item: item,
        priority: priority,
        action_label: action_label
      )
    end
  end
end
