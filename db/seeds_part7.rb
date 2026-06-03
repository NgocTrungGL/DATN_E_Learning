# =============================================================================
# PART 7 — Reviews · Quiz Attempts · Quiz Answers · Certificates
# =============================================================================

# ── Re-query state ────────────────────────────────────────────────────────────
all_enrollments = Enrollment
  .where(status: %w[active completed])
  .pluck(:user_id, :course_id, :status)

course_instructor = Course.pluck(:id, :created_by).to_h

# ─────────────────────────────────────────────────────────────────────────────
# STEP 10: REVIEWS  (~12,000)
# ─────────────────────────────────────────────────────────────────────────────
step '(10/16) Creating reviews (~12,000)'

# Rating weight pool: 5★×45, 4★×30, 3★×15, 2★×7, 1★×3
RATING_POOL = ([5]*45 + [4]*30 + [3]*15 + [2]*7 + [1]*3).freeze

REVIEW_TEXTS_BY_STAR = {
  5 => REVIEWS_5_STARS,
  4 => REVIEWS_4_STARS,
  3 => REVIEWS_3_STARS,
  2 => REVIEWS_2_STARS,
  1 => REVIEWS_1_STAR
}.freeze

review_rows    = []
reviewed_set   = Set.new   # [user_id, course_id]

# ~30% of active + 55% of completed enrollments leave a review
all_enrollments.each do |uid, cid, status|
  threshold = status == 'completed' ? 0.55 : 0.30
  next unless rand < threshold

  key = [uid, cid]
  next if reviewed_set.include?(key)
  reviewed_set.add(key)

  rating   = RATING_POOL.sample
  body_arr = REVIEW_TEXTS_BY_STAR[rating]
  # Pick deterministically but vary per user+course
  body     = body_arr[(uid.to_i + cid.to_i) % body_arr.size]

  review_rows << {
    user_id:    uid,
    course_id:  cid,
    rating:     rating,
    content:    body,
    created_at: ts(rand(1..400)),
    updated_at: ts(rand(0..30))
  }
end

batch_insert(Review, review_rows)
ok(Review.count, 'reviews')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 11: QUIZ ATTEMPTS + QUIZ ANSWERS
# ─────────────────────────────────────────────────────────────────────────────
step '(11/16) Creating quiz attempts & answers'

# Build maps needed for answer generation
course_quiz_list = Quiz.pluck(:id, :course_id).each_with_object({}) { |(qid, cid), h| (h[cid] ||= []) << qid }
# For each quiz: which question_ids are assigned?
quiz_question_map = QuizQuestion.pluck(:quiz_id, :question_id).each_with_object({}) { |(qzid, qid), h| (h[qzid] ||= []) << qid }
# For each question: correct option_id + all option_ids
question_options_map = {}   # question_id => { correct_id:, all_ids: [] }
QuestionOption.pluck(:id, :question_id, :is_correct).each do |oid, qid, correct|
  entry = question_options_map[qid] ||= { correct_id: nil, all_ids: [] }
  entry[:all_ids] << oid
  entry[:correct_id] = oid if correct
end

attempt_rows = []
answer_rows  = []

# Only generate attempts for ~35% of active/completed enrollments
sampled_enrls = all_enrollments.select { rand < 0.35 }

ATTEMPT_STATUSES = %w[completed completed completed in_progress abandoned].freeze

sampled_enrls.each do |uid, cid, enrl_status|
  quizzes = course_quiz_list[cid] || []
  next if quizzes.empty?

  # Take 1-2 quizzes per enrollment
  quizzes.sample([2, quizzes.size].min).each do |qzid|
    pass     = rand < 0.68    # 68% pass rate
    score    = pass ? rand(70.0..99.0).round(2) : rand(20.0..69.0).round(2)
    duration = rand(300..2400)
    a_status = enrl_status == 'completed' ? 'completed' : ATTEMPT_STATUSES.sample
    days_ago = rand(1..300)

    attempt_rows << {
      quiz_id:          qzid,
      user_id:          uid,
      started_at:       ts(days_ago, 1),
      finished_at:      a_status == 'completed' ? ts(days_ago) : nil,
      score:            a_status == 'completed' ? score : nil,
      is_passed:        a_status == 'completed' && pass,
      status:           a_status,
      duration_seconds: duration
    }
  end
end

QuizAttempt.insert_all(attempt_rows) unless attempt_rows.empty?
ok(QuizAttempt.count, 'quiz_attempts')

# Generate answers for completed attempts only (keep answer count reasonable)
all_attempts = QuizAttempt.where(status: 'completed').pluck(:id, :quiz_id, :user_id)

all_attempts.each_slice(300) do |slice|
  a_rows = []
  slice.each do |attempt_id, qzid, uid|
    q_ids = quiz_question_map[qzid] || []
    next if q_ids.empty?

    q_ids.each do |qid|
      opts      = question_options_map[qid]
      next unless opts&.dig(:all_ids)&.any?

      correct_id = opts[:correct_id]
      all_ids    = opts[:all_ids]
      # 65% chance of picking the correct answer (weighted toward correct)
      chosen_id  = rand < 0.65 ? correct_id : all_ids.reject { |id| id == correct_id }.sample || correct_id
      is_correct = chosen_id == correct_id

      a_rows << {
        quiz_attempt_id:    attempt_id,
        question_id:        qid,
        question_option_id: chosen_id,
        selected_option_ids: [chosen_id],
        is_correct:         is_correct,
        answered_at:        ts(rand(0..200)),
        score_earned:       is_correct ? 10.0 : 0.0
      }
    end
  end
  QuizAnswer.insert_all(a_rows) unless a_rows.empty?
end

ok(QuizAnswer.count, 'quiz_answers')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 12: CERTIFICATES
# ─────────────────────────────────────────────────────────────────────────────
step '(12/16) Creating certificates'

CERT_TEMPLATES = %w[classic modern premium minimal gold].freeze

# Issue certificates for all 'completed' enrollments
completed_enrollments = Enrollment.where(status: 'completed').pluck(:user_id, :course_id, :updated_at)

cert_rows    = []
cert_seen    = Set.new   # [user_id, course_id]

completed_enrollments.each do |uid, cid, completed_at|
  key = [uid, cid]
  next if cert_seen.include?(key)
  cert_seen.add(key)

  cert_rows << {
    user_id:          uid,
    course_id:        cid,
    certificate_code: "CERT-#{SecureRandom.hex(6).upcase}-#{uid}-#{cid}",
    issued_at:        completed_at || ts(rand(1..180)),
    template_type:    CERT_TEMPLATES.sample,
    created_at:       ts(rand(0..30)),
    updated_at:       ts(rand(0..10))
  }
end

batch_insert(Certificate, cert_rows)
ok(Certificate.count, 'certificates')
