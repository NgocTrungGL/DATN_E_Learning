# =============================================================================
# PART 6 — Enrollments & Progress Trackings
# =============================================================================

step '(8/16) Creating enrollments (~65,000)'

# ── Re-query state from DB ──────────────────────────────────────────────────
org             = Organization.first
student_ids     = User.where(role: 'student', organization_id: nil).order(:id).pluck(:id)
b2b_user_ids    = User.where(organization_id: org.id).pluck(:id)
instructor_ids  = User.where(role: 'instructor').order(:id).pluck(:id)
all_course_ids  = Course.where(status: :published).order(:id).pluck(:id)   # published only
course_prices   = Course.pluck(:id, :price).to_h

# shuffle so slices aren't alphabetically biased
shuffled_courses = all_course_ids.shuffle(random: Random.new(42))
total_c          = shuffled_courses.size
popular_courses  = shuffled_courses.first((total_c * 0.10).to_i)            # top 10%
average_courses  = shuffled_courses[(total_c * 0.10).to_i, (total_c * 0.55).to_i]  # next 55%
niche_courses    = shuffled_courses[(total_c * 0.65).to_i..]                # remaining 35%

enrollment_rows  = []
enrolled_set     = Set.new

enroll_status_weights = [
  ['active',    60],
  ['completed', 25],
  ['pending',   10],
  ['cancelled',  5]
].flat_map { |s, w| [s] * w }

def pick_enroll_status(weights) = weights.sample

add_enrollment = lambda do |uid, cid, days_ago_range|
  key = [uid, cid]
  return if enrolled_set.include?(key)
  enrolled_set.add(key)
  status     = pick_enroll_status(enroll_status_weights)
  days_ago   = rand(days_ago_range)
  price      = course_prices[cid] || 0.0
  # completed students may have paid, active may have discount
  paid_price = case status
               when 'completed' then price
               when 'active'    then [price * rand(0.7..1.0), price].min.round(2)
               when 'pending'   then price
               else 0.0
               end
  enrollment_rows << {
    user_id:     uid,
    course_id:   cid,
    status:      status,
    price:       paid_price,
    enrolled_at: ts(days_ago),
    created_at:  ts(days_ago),
    updated_at:  ts(rand(0..days_ago))
  }
end

# Popular courses: 350–700 students each (recent enrollments skewed)
popular_courses.each do |cid|
  n = rand(350..700)
  student_ids.sample(n, random: Random.new(cid)).each { |sid| add_enrollment.call(sid, cid, 30..540) }
end

# Average courses: 70–200 students each
average_courses.each do |cid|
  n = rand(70..200)
  student_ids.sample(n, random: Random.new(cid)).each { |sid| add_enrollment.call(sid, cid, 10..400) }
end

# Niche courses: 5–40 students each
niche_courses.each do |cid|
  n = rand(5..40)
  student_ids.sample(n, random: Random.new(cid)).each { |sid| add_enrollment.call(sid, cid, 5..300) }
end

# B2B users: enroll in 5–15 courses each (via org licenses)
b2b_user_ids.each do |uid|
  all_course_ids.sample(rand(5..15)).each { |cid| add_enrollment.call(uid, cid, 30..180) }
end

# Each instructor is enrolled in their own courses + 3-8 other courses
Course.pluck(:id, :created_by).each do |cid, inst_id|
  next unless inst_id
  add_enrollment.call(inst_id, cid, 300..700)
end
instructor_ids.sample(150).each do |iid|
  all_course_ids.sample(rand(3..8)).each { |cid| add_enrollment.call(iid, cid, 60..365) }
end

batch_insert(Enrollment, enrollment_rows)
ok(Enrollment.count, 'enrollments')

# =============================================================================
# STEP 9: PROGRESS TRACKINGS
# =============================================================================
step '(9/16) Creating progress trackings'

# Build course → lesson IDs + quiz IDs maps
course_module_ids = CourseModule.pluck(:id, :course_id).each_with_object({}) do |(mid, cid), h|
  (h[cid] ||= []) << mid
end
module_lesson_ids = Lesson.pluck(:id, :course_module_id).each_with_object({}) do |(lid, mid), h|
  (h[mid] ||= []) << lid
end
course_lesson_ids = course_module_ids.transform_values do |mids|
  mids.flat_map { |mid| module_lesson_ids[mid] || [] }
end
course_quiz_ids = Quiz.pluck(:id, :course_id).each_with_object({}) do |(qid, cid), h|
  (h[cid] ||= []) << qid
end

# Load enrollments; only generate progress for active & completed
# (keeping to a practical record count while still providing rich analytics data)
active_completed = Enrollment
  .where(status: %w[active completed])
  .pluck(:user_id, :course_id, :status, :enrolled_at)

# Sample ~40% of active, 100% of completed
completed_enrls = active_completed.select { |_, _, s, _| s == 'completed' }
active_enrls    = active_completed.select { |_, _, s, _| s == 'active' }.sample(
  (active_completed.count { |_, _, s, _| s == 'active' } * 0.40).to_i,
  random: Random.new(7)
)
progress_enrls  = completed_enrls + active_enrls

pt_rows        = []
pt_lesson_seen = Set.new   # enforce unique [user_id, lesson_id]
pt_quiz_seen   = Set.new   # enforce unique [user_id, quiz_id]

progress_enrls.each_slice(500) do |slice|
  slice.each do |uid, cid, status, enrolled_at|
    lesson_ids = course_lesson_ids[cid] || []
    quiz_ids   = course_quiz_ids[cid]   || []
    next if lesson_ids.empty?

    # Decide how many lessons to mark complete
    completion_pct = case status
                     when 'completed' then rand(0.88..1.0)
                     when 'active'    then rand(0.15..0.75)
                     end

    n_complete  = (lesson_ids.size * completion_pct).ceil
    n_progress  = status == 'active' ? [1, (lesson_ids.size * 0.1).ceil].max : 0
    # Shuffle deterministically per-user/course pair
    shuffled_lessons = lesson_ids.shuffle(random: Random.new(uid.to_i ^ cid.to_i))

    shuffled_lessons.each_with_index do |lid, i|
      lesson_key = [uid, lid]
      next if pt_lesson_seen.include?(lesson_key)
      pt_lesson_seen.add(lesson_key)

      lesson_status = if i < n_complete
                        'completed'
                      elsif i < n_complete + n_progress
                        'in_progress'
                      else
                        'not_started'
                      end
      progress_val = lesson_status == 'completed' ? 100.0 : (lesson_status == 'in_progress' ? rand(10.0..85.0).round(2) : 0.0)

      pt_rows << {
        user_id:        uid,
        course_id:      cid,
        lesson_id:      lid,
        quiz_id:        nil,
        progress_type:  'lesson',
        status:         lesson_status,
        progress_value: progress_val,
        created_at:     ts(rand(0..180)),
        updated_at:     ts(rand(0..30))
      }
    end

    # Quiz progress: only if partially or fully done
    if status == 'completed' || (status == 'active' && completion_pct > 0.4)
      quiz_ids.sample(rand(1..[quiz_ids.size, 3].min)).each do |qid|
        quiz_key = [uid, qid]
        next if pt_quiz_seen.include?(quiz_key)
        pt_quiz_seen.add(quiz_key)

        qstatus = status == 'completed' ? 'completed' : %w[completed in_progress].sample
        pt_rows << {
          user_id:        uid,
          course_id:      cid,
          lesson_id:      nil,
          quiz_id:        qid,
          progress_type:  'quiz',
          status:         qstatus,
          progress_value: qstatus == 'completed' ? 100.0 : rand(30.0..90.0).round(2),
          created_at:     ts(rand(0..120)),
          updated_at:     ts(rand(0..20))
        }
      end
    end
  end

  # Flush every 500-enrollment slice
  unless pt_rows.empty?
    batch_insert(ProgressTracking, pt_rows)
    pt_rows.clear
  end
end

batch_insert(ProgressTracking, pt_rows) unless pt_rows.empty?
ok(ProgressTracking.count, 'progress_trackings')
