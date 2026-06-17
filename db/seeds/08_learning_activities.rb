# frozen_string_literal: true
# db/seeds/08_learning_activities.rb

module SeedLearningActivities
  ACTIVITY_TYPES = %w[lesson_view quiz_attempt note_taken lesson_complete course_start].freeze

  def self.run!
    now        = SeedHelpers::NOW
    enrollments = Enrollment.where(status: %w[active completed]).to_a
    lessons     = Lesson.joins(:course_module)
                        .order(:id)
                        .pluck(:id, 'course_modules.course_id', :cached_duration_seconds)

    lesson_by_course = Hash.new { |h, k| h[k] = [] }
    lessons.each { |id, cid, dur| lesson_by_course[cid] << [id, dur] }

    activities_batch = []

    # Generate daily learning sessions per enrolled user
    enrollments.each do |enrollment|
      course_lessons = lesson_by_course[enrollment.course_id]
      next if course_lessons.empty?

      # Number of study days
      total_days = ((now - enrollment.enrolled_at) / 86_400).ceil
      next if total_days <= 0

      active_days = case rand(10)
                    when 0    then (total_days * rand(0.01..0.05)).ceil   # Dropped off
                    when 1..3 then (total_days * rand(0.05..0.20)).ceil   # Occasional
                    when 4..6 then (total_days * rand(0.20..0.50)).ceil   # Regular
                    when 7..8 then (total_days * rand(0.50..0.80)).ceil   # Active
                    else           (total_days * rand(0.70..0.95)).ceil   # Dedicated
                    end

      active_days = [active_days, 1].max

      # Spread active days across the enrollment period
      study_dates = active_days.times.map do
        SeedHelpers.rand_date(
          enrollment.enrolled_at.to_date,
          [now.to_date, enrollment.enrolled_at.to_date + total_days].min
        )
      end.uniq.sort

      study_dates.each do |date|
        sessions_per_day = rand(1..3)
        sessions_per_day.times do
          lesson_data = course_lessons.sample
          lesson_id, duration = lesson_data

          activities_batch << {
            user_id:          enrollment.user_id,
            course_id:        enrollment.course_id,
            lesson_id:        lesson_id,
            activity_type:    ACTIVITY_TYPES.sample,
            duration_seconds: duration || rand(600..3600),
            score:            nil,
            activity_date:    date,
            created_at:       date.to_time + rand(6..22).hours + rand(60).minutes,
            updated_at:       date.to_time + rand(6..22).hours + rand(60).minutes,
          }
        end
      end

      if activities_batch.size >= 5000
        LearningActivity.insert_all(activities_batch)
        activities_batch = []
      end
    end

    # Supplemental activities (quiz attempts)
    QuizAttempt.order(Arel.sql('RANDOM()')).limit(500).each do |attempt|
      enrollment = enrollments.find { |e| e.user_id == attempt.user_id }
      next unless enrollment

      activities_batch << {
        user_id:          attempt.user_id,
        course_id:        enrollment.course_id,
        lesson_id:        nil,
        activity_type:    'quiz_attempt',
        duration_seconds: attempt.duration_seconds || rand(600..1800),
        score:            attempt.score&.to_i,
        activity_date:    attempt.started_at&.to_date || SeedHelpers.rand_date(enrollment.enrolled_at.to_date),
        created_at:       attempt.started_at || now,
        updated_at:       attempt.finished_at || now,
      }
    end

    LearningActivity.insert_all(activities_batch) if activities_batch.any?
    puts "  ✓ #{LearningActivity.count} learning activities"

    # ── Learning streaks ─────────────────────────────────────
    streaks_batch = []
    User.where(role: 'student').find_each do |user|
      last_dates = LearningActivity.where(user_id: user.id)
                                   .order(:activity_date)
                                   .pluck(:activity_date)
                                   .uniq

      current_streak = 0
      longest_streak = 0
      temp_streak    = 0
      prev_date      = nil

      last_dates.each do |d|
        if prev_date.nil? || d == prev_date + 1
          temp_streak += 1
        else
          temp_streak = 1
        end
        longest_streak = [longest_streak, temp_streak].max
        prev_date      = d
      end

      current_streak = (last_dates.last == now.to_date || last_dates.last == now.to_date - 1) ? temp_streak : 0

      streaks_batch << {
        user_id:              user.id,
        current_streak:       current_streak,
        longest_streak:       longest_streak,
        last_activity_date:   last_dates.last,
        weekly_activity_days: [last_dates.count { |d| d >= 7.days.ago.to_date }, 7].min,
        created_at:           user.created_at,
        updated_at:           now,
      }
    end
    LearningStreak.insert_all(streaks_batch)
    puts "  ✓ #{streaks_batch.length} learning streaks"

    # ── Learning goals ────────────────────────────────────────
    goals_batch = []
    seen_goals  = Set.new
    week_starts = 4.times.map { |i| (now - i.weeks).beginning_of_week.to_date }

    User.where(role: 'student').order(Arel.sql('RANDOM()')).limit(400).each do |user|
      week_starts.first(rand(1..3)).each do |week_start|
        goal_type = %w[study_minutes lessons_completed courses_started].sample
        key = [user.id, week_start, goal_type]
        next if seen_goals.include?(key)
        seen_goals.add(key)

        target = case goal_type
                 when 'study_minutes'     then [30, 60, 90, 120, 180].sample
                 when 'lessons_completed' then [3, 5, 7, 10].sample
                 else [1, 2].sample
                 end

        current = rand(0..target + 2)

        goals_batch << {
          user_id:       user.id,
          goal_type:     goal_type,
          target_value:  target,
          current_value: [current, target + 2].min,
          week_start:    week_start,
          is_active:     week_start == week_starts.first,
          created_at:    week_start.to_time,
          updated_at:    now,
        }
      end
    end
    LearningGoal.insert_all(goals_batch)
    puts "  ✓ #{goals_batch.length} learning goals"
  end
end
