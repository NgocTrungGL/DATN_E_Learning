# frozen_string_literal: true
# db/seeds/07_progress.rb

module SeedProgress
  def self.run!
    now         = SeedHelpers::NOW
    enrollments = Enrollment.where(status: %w[active completed]).to_a
    lesson_ids_by_course = Hash.new { |h, k| h[k] = [] }
    Lesson.joins(:course_module)
          .order('course_modules.order_index, lessons.order_index')
          .pluck(:id, 'course_modules.course_id')
          .each { |lesson_id, course_id| lesson_ids_by_course[course_id] << lesson_id }
    quizzes_by_course = Quiz.order(:id).select(:id, :course_id, :pass_score).group_by(&:course_id)

    progress_batch = []
    seen_lesson    = Set.new
    seen_quiz      = Set.new

    enrollments.each_with_index do |enrollment, ei|
      lesson_ids = lesson_ids_by_course[enrollment.course_id]
      quizzes = quizzes_by_course[enrollment.course_id] || []

      next if lesson_ids.empty?

      # Determine how far this learner has progressed
      completion_tier = case rand(10)
                        when 0..1 then :not_started
                        when 2..3 then :early        # <25%
                        when 4..5 then :mid          # 25–60%
                        when 6..7 then :late         # 60–90%
                        else           :complete     # 100%
                        end

      lesson_count = case completion_tier
                     when :not_started then 0
                     when :early       then [1, (lesson_ids.size * 0.25).ceil].min
                     when :mid         then (lesson_ids.size * rand(0.25..0.60)).ceil
                     when :late        then (lesson_ids.size * rand(0.60..0.90)).ceil
                     when :complete    then lesson_ids.size
                     end

      completed_lesson_ids = lesson_ids.first(lesson_count)

      completed_lesson_ids.each do |lesson_id|
        key = [enrollment.user_id, lesson_id]
        next if seen_lesson.include?(key)
        seen_lesson.add(key)

        started_at  = SeedHelpers.rand_time(enrollment.enrolled_at, now)
        finished_at = started_at + rand(600..3600).seconds

        progress_batch << {
          user_id:        enrollment.user_id,
          course_id:      enrollment.course_id,
          lesson_id:      lesson_id,
          quiz_id:        nil,
          progress_type:  'lesson',
          status:         'completed',
          progress_value: 100.0,
          created_at:     started_at,
          updated_at:     finished_at,
        }
      end

      # In-progress lesson (the next one after completed)
      in_progress_lesson_id = lesson_ids[lesson_count]
      if in_progress_lesson_id && completion_tier != :not_started
        key = [enrollment.user_id, in_progress_lesson_id]
        unless seen_lesson.include?(key)
          seen_lesson.add(key)
          pct = rand(5.0..85.0).round(2)
          started_at = SeedHelpers.rand_time(enrollment.enrolled_at, now)
          progress_batch << {
            user_id:        enrollment.user_id,
            course_id:      enrollment.course_id,
            lesson_id:      in_progress_lesson_id,
            quiz_id:        nil,
            progress_type:  'lesson',
            status:         'in_progress',
            progress_value: pct,
            created_at:     started_at,
            updated_at:     SeedHelpers.rand_time(started_at, now),
          }
        end
      end

      # Quiz progress
      quizzes.first([quizzes.size, (lesson_count / 5.0).ceil].min).each do |quiz|
        key = [enrollment.user_id, quiz.id]
        next if seen_quiz.include?(key)
        seen_quiz.add(key)

        score       = rand(45..100).to_f
        is_passed   = score >= (quiz.pass_score || 70)
        started_at  = SeedHelpers.rand_time(enrollment.enrolled_at, now)

        progress_batch << {
          user_id:        enrollment.user_id,
          course_id:      enrollment.course_id,
          lesson_id:      nil,
          quiz_id:        quiz.id,
          progress_type:  'quiz',
          status:         is_passed ? 'completed' : 'in_progress',
          progress_value: score,
          created_at:     started_at,
          updated_at:     started_at + rand(10..45).minutes,
        }
      end

      # Course-level progress row
      course_pct = case completion_tier
                   when :not_started then 0.0
                   when :early       then rand(1.0..24.0).round(2)
                   when :mid         then rand(25.0..59.0).round(2)
                   when :late        then rand(60.0..95.0).round(2)
                   when :complete    then 100.0
                   end

      progress_batch << {
        user_id:        enrollment.user_id,
        course_id:      enrollment.course_id,
        lesson_id:      nil,
        quiz_id:        nil,
        progress_type:  'course',
        status:         completion_tier == :complete ? 'completed' : (course_pct > 0 ? 'in_progress' : 'not_started'),
        progress_value: course_pct,
        created_at:     enrollment.enrolled_at,
        updated_at:     SeedHelpers.rand_time(enrollment.enrolled_at, now),
      }

      if progress_batch.size >= 3000
        ProgressTracking.insert_all(progress_batch)
        progress_batch = []
      end
    end

    ProgressTracking.insert_all(progress_batch) if progress_batch.any?
    puts "  ✓ #{ProgressTracking.count} progress records"

    # ── Quiz attempts ────────────────────────────────────────
    attempts_batch = []
    answers_batch  = []

    quiz_progresses = ProgressTracking.where(progress_type: 'quiz').to_a
    questions_by_quiz = QuizQuestion.includes(:question).group_by(&:quiz_id)

    quiz_progresses.sample(2000).each do |pt|
      quiz        = Quiz.find_by(id: pt.quiz_id)
      next unless quiz

      attempt_count = SeedHelpers.chance(30) ? 2 : 1  # 30% retake
      attempt_count.times do |attempt_n|
        score      = attempt_n == 0 ? pt.progress_value : rand(50..100).to_f
        is_passed  = score >= (quiz.pass_score || 70)
        started_at = SeedHelpers.rand_time(pt.created_at, now)
        duration   = rand(600..2700)

        attempts_batch << {
          quiz_id:          quiz.id,
          user_id:          pt.user_id,
          started_at:       started_at,
          finished_at:      started_at + duration.seconds,
          score:            score,
          is_passed:        is_passed,
          status:           'completed',
          duration_seconds: duration,
        }
      end
    end

    QuizAttempt.insert_all(attempts_batch)
    puts "  ✓ #{attempts_batch.length} quiz attempts"
  end
end
