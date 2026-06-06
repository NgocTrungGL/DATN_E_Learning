class GoalProgressService
  def self.update_user_goals(user)
    active_goals = user.learning_goals.active.current_week
    return if active_goals.empty?

    week_start = Time.current.beginning_of_week.to_date
    now = Date.current

    active_goals.each do |goal|
      new_value = case goal.goal_type
                  when "lessons_per_week"
                    user.lesson_completions_count(from_date: week_start, to_date: now)
                  when "hours_per_week"
                    (user.total_study_seconds(from_date: week_start, to_date: now) / 3600).round
                  when "courses_per_month"
                    user.certificates.where("issued_at >= ?", 1.month.ago).count
                  when "quiz_score"
                    attempts = user.quiz_attempts.completed
                                  .where("finished_at >= ?", week_start)
                    attempts.average(:score)&.round || 0
                  else
                    0
                  end

      goal.update!(current_value: new_value) if goal.current_value != new_value
    end
  end
end
