module Learning
  # Phân loại rủi ro học tập dựa trên tiến độ, quá hạn và mức độ hoạt động.
  class StudyRiskDetector
    Risk = Struct.new(:level, :label, :score, :reasons, :recommendation, keyword_init: true)

    def initialize(profile)
      @profile = profile
    end

    def call
      score = 0
      reasons = []

      score += inactivity_score(reasons)
      score += overdue_score(reasons)
      score += skipped_score(reasons)
      score += unfinished_score(reasons)
      score += workload_score(reasons)

      Risk.new(
        level: level_for(score),
        label: label_for(score),
        score: score.clamp(0, 100),
        reasons: reasons,
        recommendation: recommendation_for(score)
      )
    end

    private

    attr_reader :profile

    def inactivity_score(reasons)
      days = profile.inactive_days
      return 25.tap { reasons << "No learning activity has been recorded yet." } if days.nil?
      return 35.tap { reasons << "No activity in #{days} days." } if days >= 7
      return 20.tap { reasons << "No activity in #{days} days." } if days >= 3

      0
    end

    def overdue_score(reasons)
      count = profile.overdue_items_count.to_i
      return 35.tap { reasons << "#{count} study plan items are overdue." } if count >= 5
      return 20.tap { reasons << "#{count} study plan items are overdue." } if count >= 2
      return 10.tap { reasons << "1 study plan item is overdue." } if count == 1

      0
    end

    def skipped_score(reasons)
      count = profile.skipped_items_count.to_i
      return 15.tap { reasons << "#{count} lessons were skipped." } if count >= 3
      return 8.tap { reasons << "#{count} lesson was skipped." } if count.positive?

      0
    end

    def unfinished_score(reasons)
      count = profile.in_progress_items_count.to_i
      return 10.tap { reasons << "#{count} lessons are still in progress." } if count >= 3
      return 6.tap { reasons << "A lesson is waiting to be resumed." } if count.positive?

      0
    end

    def workload_score(reasons)
      required = profile.required_daily_minutes.to_i
      capacity = profile.daily_capacity_minutes.to_i
      return 0 if required.zero? || capacity.zero?
      return 25.tap { reasons << "The remaining plan needs #{required} minutes/day, above the current #{capacity} minute pace." } if required > capacity * 1.5
      return 12.tap { reasons << "The remaining plan is slightly above the current study pace." } if required > capacity * 1.15

      0
    end

    def level_for(score)
      return :at_risk if score >= 50
      return :behind if score >= 25
      return :needs_attention if score >= 10

      :on_track
    end

    def label_for(score)
      {
        at_risk: "At risk",
        behind: "Behind schedule",
        needs_attention: "Needs attention",
        on_track: "On track"
      }.fetch(level_for(score))
    end

    def recommendation_for(score)
      case level_for(score)
      when :at_risk
        "Start with a short catch-up session and adjust the remaining plan."
      when :behind
        "Focus on overdue or unfinished lessons before continuing."
      when :needs_attention
        "Clear the highest priority item today to keep momentum."
      else
        "Continue with the next scheduled lesson."
      end
    end
  end
end
