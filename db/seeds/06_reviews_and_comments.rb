# frozen_string_literal: true
# db/seeds/06_reviews_and_comments.rb

module SeedReviewsAndComments
  def self.run!
    now         = SeedHelpers::NOW
    enrollments = Enrollment.where(status: %w[active completed]).includes(:user, :course).to_a
    lesson_ids_by_course = Hash.new { |h, k| h[k] = [] }
    Lesson.joins(:course_module)
          .order(:id)
          .pluck(:id, 'course_modules.course_id')
          .each { |lesson_id, course_id| lesson_ids_by_course[course_id] << lesson_id }
    students    = User.where(role: 'student').to_a

    # ── Reviews ──────────────────────────────────────────────
    reviewed_pairs  = Set.new
    reviews_batch   = []

    # Rating distribution: 5★ 45%, 4★ 30%, 3★ 15%, 2★ 7%, 1★ 3%
    rating_pool = ([5] * 45) + ([4] * 30) + ([3] * 15) + ([2] * 7) + ([1] * 3)

    enrollments.shuffle.each do |enrollment|
      break if reviews_batch.size >= 1200
      key = [enrollment.user_id, enrollment.course_id]
      next if reviewed_pairs.include?(key)
      next unless SeedHelpers.chance(65)  # 65% of enrolled users leave a review

      reviewed_pairs.add(key)
      rating     = rating_pool.sample
      body_pool  = SeedHelpers::REVIEWS[rating]
      created_at = SeedHelpers.rand_time(enrollment.enrolled_at, now)

      reviews_batch << {
        user_id:    enrollment.user_id,
        course_id:  enrollment.course_id,
        rating:     rating,
        content:    body_pool.sample,
        created_at: created_at,
        updated_at: created_at,
      }
    end

    Review.insert_all(reviews_batch)
    puts "  ✓ #{reviews_batch.length} reviews (avg rating: #{reviews_batch.sum { |r| r[:rating] }.to_f / reviews_batch.size.to_f  .round(2)}★)"

    # ── Comments ─────────────────────────────────────────────
    comments_batch  = []
    parent_comments = []  # for threading

    # Each lesson in enrolled courses gets comments
    lesson_comment_map = Hash.new { |h, k| h[k] = [] }

    # Distribute ~15 comments per lesson across enrolled lessons
    enrollments.each do |enrollment|
      course_lesson_ids = lesson_ids_by_course[enrollment.course_id]
      next if course_lesson_ids.empty?

      # Sample a few lessons this user commented on
      rand(0..3).times do
        lesson_id = course_lesson_ids.sample
        next unless lesson_id

        commented_at = SeedHelpers.rand_time(enrollment.enrolled_at, now)
        comment_row = {
          user_id:    enrollment.user_id,
          lesson_id:  lesson_id,
          body:       SeedHelpers::COMMENTS.sample,
          parent_id:  nil,
          created_at: commented_at,
          updated_at: commented_at,
        }
        comments_batch << comment_row
        lesson_comment_map[lesson_id] << comments_batch.size - 1
      end

      if comments_batch.size >= 4000
        Comment.insert_all(comments_batch)
        comments_batch = []
        lesson_comment_map.clear
      end
    end

    # Flush remaining
    Comment.insert_all(comments_batch) if comments_batch.any?

    # ── Add threaded replies to some comments ─────────────────
    parent_ids = Comment.order(Arel.sql('RANDOM()')).limit(2000).pluck(:id, :lesson_id, :created_at)
    replies_batch = []

    parent_ids.each do |pid, lesson_id, parent_created|
      next unless SeedHelpers.chance(40)  # 40% of comments get a reply
      reply_count = rand(1..3)

      reply_count.times do
        replied_at = SeedHelpers.rand_time(parent_created, now)
        replies_batch << {
          user_id:    students.sample.id,
          lesson_id:  lesson_id,
          body:       reply_text,
          parent_id:  pid,
          created_at: replied_at,
          updated_at: replied_at,
        }
      end

      if replies_batch.size >= 3000
        Comment.insert_all(replies_batch)
        replies_batch = []
      end
    end

    Comment.insert_all(replies_batch) if replies_batch.any?
    puts "  ✓ #{Comment.count} total comments (threaded)"

    # ── Notes ────────────────────────────────────────────────
    notes_batch = []
    note_texts = [
      "Important: remember to check edge cases when input is empty.",
      "This pattern is similar to what we use at work — need to adapt it for our use case.",
      "Revisit this section before the project. Key formula here.",
      "The instructor's approach differs from the textbook — both valid, but understand why.",
      "Action item: implement this in the side project this weekend.",
      "Good reference point for interview prep — this concept comes up often.",
      "Compare with the alternative approach in Module 4.",
      "Ask about this in the Q&A — not entirely clear why this shortcut works.",
    ]

    enrollments.sample(600).each do |enrollment|
      course_lesson_ids = lesson_ids_by_course[enrollment.course_id].first(5)
      rand(1..3).times do
        lesson_id = course_lesson_ids.sample
        next unless lesson_id
        created_at = SeedHelpers.rand_time(enrollment.enrolled_at, now)
        notes_batch << {
          user_id:    enrollment.user_id,
          lesson_id:  lesson_id,
          course_id:  enrollment.course_id,
          content:    note_texts.sample,
          created_at: created_at,
          updated_at: created_at,
        }
      end
    end
    Note.insert_all(notes_batch)
    puts "  ✓ #{notes_batch.length} notes"
  end

  def self.reply_text
    [
      "Thanks for asking — the answer is to check the documentation for the version you are using.",
      "I had the same issue! Turned out I had a typo in the configuration.",
      "This is a known quirk in this version. Upgrading resolves it.",
      "Great question. The instructor addressed this in the Q&A around week 2.",
      "I found this Stack Overflow answer helpful for this exact issue.",
      "Same problem here. Switching from the legacy API to the new one fixed it.",
      "You need to restart the dev server after making that change.",
    ].sample
  end
  private_class_method :reply_text

end
