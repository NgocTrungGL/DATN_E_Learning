class LearningActivityService
  def self.track_lesson_view(user, lesson)
    activity = user.learning_activities.find_or_initialize_by(
      activity_type: :lesson_view,
      activity_date: Date.current,
      lesson: lesson
    )
    activity.course = lesson.course if lesson.present?
    activity.save! if activity.new_record?
    activity
  end

  def self.track_lesson_duration(user, lesson, seconds)
    activity = user.learning_activities.find_or_initialize_by(
      activity_type: :lesson_view,
      activity_date: Date.current,
      lesson: lesson
    )
    activity.course = lesson.course
    activity.duration_seconds = (activity.duration_seconds || 0) + seconds
    activity.save!
  end

  def self.track_activity(user:, course: nil, lesson: nil, activity_type:, duration_seconds: 0, score: nil)
    user.learning_activities.create!(
      user: user,
      course: course,
      lesson: lesson,
      activity_type: activity_type,
      duration_seconds: duration_seconds,
      score: score,
      activity_date: Date.current
    )
  end

  def self.finalize_session(user)
    user.learning_streak_record.update_streak!(Date.current)
  end
end
