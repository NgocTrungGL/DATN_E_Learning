# =============================================================================
# PART 9 — Notes · Wishlists · Carts · Coupons · Notifications
#           Wallet Transactions · Payout Requests · Course Similarities
#           User Recommendations · Message Reactions · Licenses · Invoices
#           Final Activation
# =============================================================================

# ── Re-query state ────────────────────────────────────────────────────────────
admin_user       = User.find_by(role: 'admin')
org              = Organization.first
student_ids      = User.where(role: 'student', organization_id: nil).order(:id).pluck(:id)
b2b_user_ids     = User.where(organization_id: org.id).pluck(:id)
instructor_ids   = User.where(role: 'instructor').order(:id).pluck(:id)
all_course_ids   = Course.where(status: :published).order(:id).pluck(:id)
course_prices    = Course.pluck(:id, :price).to_h
course_inst_map  = Course.pluck(:id, :created_by).to_h

enrolled_courses_per_user = Enrollment
  .where(status: %w[active completed])
  .pluck(:user_id, :course_id)
  .each_with_object({}) { |(uid, cid), h| (h[uid] ||= []) << cid }

# course_id => [user_ids] (needed for reactions)
enrolled_per_course = Enrollment
  .where(status: %w[active completed])
  .pluck(:user_id, :course_id)
  .each_with_object({}) { |(uid, cid), h| (h[cid] ||= []) << uid }

active_student_ids = Enrollment.where(status: %w[active completed])
  .distinct.pluck(:user_id).select { |id| student_ids.include?(id) }

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15A: NOTES
# ─────────────────────────────────────────────────────────────────────────────
step '(15a/16) Creating notes'

NOTE_BODIES = [
  'Điểm quan trọng cần nhớ: luôn validate input trước khi xử lý.',
  'Cần xem lại phần này — concept còn hơi mờ.',
  'TODO: thực hành lại ví dụ trong bài với dataset của mình.',
  'Key insight: phương pháp này scale tốt hơn approach truyền thống O(n²) → O(n log n).',
  'Link tài liệu bổ sung: docs chính thức có giải thích rõ hơn phần edge cases.',
  'Formula cần nhớ cho exam/interview.',
  'Pattern này xuất hiện nhiều trong real-world code. Cần quen tay.',
  'Tóm tắt: bước 1 → 2 → 3. Đừng skip bước 2.',
  'Lỗi phổ biến: nhầm giữa X và Y. Luôn kiểm tra type trước.',
  'Best practice: viết test trước khi implement (TDD approach).',
  'Reminder: đọc lại bài này trước buổi mentoring cuối tháng.',
  'Đây là prerequisite cho module tiếp theo. Chắc chắn phải nắm.',
  'Quick note: cách tối ưu này tiết kiệm ~40% memory so với naive solution.',
  'Study later: tìm hiểu thêm về advanced variant của technique này.',
  'Interview tip: giải thích tradeoff được hỏi nhiều trong system design rounds.',
].freeze

note_rows = []

# ~8% of active/completed enrollments generate notes
Enrollment.where(status: %w[active completed])
  .pluck(:user_id, :course_id)
  .select { rand < 0.08 }
  .each do |uid, cid|
    cmod_id = CourseModule.where(course_id: cid).pluck(:id).first
    next unless cmod_id
    lid = Lesson.where(course_module_id: cmod_id).pluck(:id).first
    next unless lid

    rand(1..3).times do |ni|
      note_rows << {
        user_id:    uid,
        lesson_id:  lid,
        course_id:  cid,
        content:    NOTE_BODIES[(uid.to_i + ni) % NOTE_BODIES.size],
        created_at: ts(rand(1..180)),
        updated_at: ts(rand(0..30))
      }
    end
  end

batch_insert(Note, note_rows)
ok(Note.count, 'notes')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15B: WISHLISTS
# ─────────────────────────────────────────────────────────────────────────────
step '(15b/16) Creating wishlists'

wishlist_rows = []
wishlist_seen = Set.new

# ~22% of students have wishlist items (non-enrolled courses they want)
student_ids.sample((student_ids.size * 0.22).to_i).each do |uid|
  enrolled    = (enrolled_courses_per_user[uid] || []).to_set
  candidates  = all_course_ids.reject { |cid| enrolled.include?(cid) }
  next if candidates.empty?

  candidates.sample(rand(2..8)).each do |cid|
    key = [uid, cid]
    next if wishlist_seen.include?(key)
    wishlist_seen.add(key)
    wishlist_rows << {
      user_id:    uid,
      course_id:  cid,
      created_at: ts(rand(1..300)),
      updated_at: ts(rand(0..30))
    }
  end
end

batch_insert(Wishlist, wishlist_rows)
ok(Wishlist.count, 'wishlists')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15C: CARTS + CART ITEMS
# ─────────────────────────────────────────────────────────────────────────────
step '(15c/16) Creating carts & cart items'

PROMO_CODES = %w[SUMMER2025 EDTECH30 NEWLEARNER FLASH50 nil nil nil nil].freeze

# ~15% of students have active carts
cart_students = student_ids.sample((student_ids.size * 0.15).to_i)

cart_rows = cart_students.map.with_index do |uid, i|
  {
    user_id:    uid,
    promo_code: PROMO_CODES[i % PROMO_CODES.size] == 'nil' ? nil : PROMO_CODES[i % PROMO_CODES.size],
    created_at: ts(rand(1..60)),
    updated_at: ts(rand(0..10))
  }
end

Cart.insert_all(cart_rows) unless cart_rows.empty?

cart_id_map = Cart.pluck(:user_id, :id).to_h   # user_id => cart_id

cart_item_rows = []
ci_seen        = Set.new

cart_students.each do |uid|
  cart_id  = cart_id_map[uid]
  next unless cart_id

  enrolled = (enrolled_courses_per_user[uid] || []).to_set
  candidates = all_course_ids.reject { |cid| enrolled.include?(cid) }.sample(rand(1..5))
  candidates.each do |cid|
    key = [cart_id, cid]
    next if ci_seen.include?(key)
    ci_seen.add(key)
    cart_item_rows << {
      cart_id:    cart_id,
      course_id:  cid,
      created_at: ts(rand(1..60)),
      updated_at: ts(rand(0..10))
    }
  end
end

batch_insert(CartItem, cart_item_rows)
ok(CartItem.count, 'cart_items')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15D: COUPONS
# ─────────────────────────────────────────────────────────────────────────────
step '(15d/16) Creating coupons'

COUPON_DEFS = [
  { code: 'WELCOME20',  type: 0, value: 20.00, target: 0, limit: 500,  status: 0 },
  { code: 'SUMMER2025', type: 0, value: 30.00, target: 0, limit: 200,  status: 0 },
  { code: 'FLASH50PCT', type: 0, value: 50.00, target: 0, limit: 100,  status: 0 },
  { code: 'VIP100K',    type: 1, value: 100000.0, target: 0, limit: 50,   status: 0 },
  { code: 'NEW2025',    type: 0, value: 15.00, target: 0, limit: 1000, status: 0 },
  { code: 'THANKYOU10', type: 0, value: 10.00, target: 0, limit: 300,  status: 0 },
  { code: 'DEVWEEK40',  type: 0, value: 40.00, target: 0, limit: 80,   status: 0 },
  { code: 'AITECH25',   type: 0, value: 25.00, target: 0, limit: 150,  status: 0 },
  { code: 'LANGLEARN',  type: 0, value: 20.00, target: 0, limit: 200,  status: 0 },
  { code: 'BIZPRO15',   type: 0, value: 15.00, target: 0, limit: 400,  status: 0 },
  { code: 'EXPIRED50',  type: 0, value: 50.00, target: 0, limit: 100,  status: 2 },  # expired
  { code: 'DRAFT10',    type: 0, value: 10.00, target: 0, limit: 0,    status: 1 },  # draft
  { code: 'ZIGEXNB2B',  type: 0, value: 35.00, target: 0, limit: 50,   status: 0 },
  { code: 'FREESTART',  type: 1, value: 50000.0, target: 0, limit: 200, status: 0 },
  { code: 'COMEBACK25', type: 0, value: 25.00, target: 0, limit: 180,  status: 0 },
].freeze

now_ts  = ts(0)
ago30   = ts(30)
ago365  = ts(365)
fut90   = (SEED_NOW + 90.days).strftime('%Y-%m-%d %H:%M:%S')
fut30   = (SEED_NOW + 30.days).strftime('%Y-%m-%d %H:%M:%S')

coupon_rows = COUPON_DEFS.map do |c|
  {
    code:          c[:code],
    discount_type: c[:type],
    discount_value: c[:value],
    start_at:      ago30,
    end_at:        c[:status] == 2 ? ago365 : fut90,
    target_type:   c[:target],
    course_id:     nil,
    creator_id:    admin_user.id,
    usage_limit:   c[:limit],
    status:        c[:status],
    usage_count:   rand(0..[c[:limit], 1].max),
    created_at:    ago30,
    updated_at:    now_ts
  }
end

Coupon.insert_all(coupon_rows)
ok(Coupon.count, 'coupons')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15E: WALLET TRANSACTIONS
# ─────────────────────────────────────────────────────────────────────────────
step '(15e/16) Creating wallet transactions'

wallet_id_map = Wallet.pluck(:user_id, :id).to_h   # user_id => wallet_id

# TRANSACTION_TYPES: 0=credit, 1=debit
tx_rows = []

# Active students: 2–6 transactions each (purchase, refund, top-up)
active_student_ids.sample((active_student_ids.size * 0.40).to_i).each do |uid|
  wid = wallet_id_map[uid]
  next unless wid

  # Initial top-up
  tx_rows << {
    wallet_id:        wid,
    amount:           [100_000, 200_000, 500_000].sample,
    transaction_type: 0,   # credit
    source_type:      'top_up',
    source_id:        nil,
    created_at:       ts(rand(30..365)),
    updated_at:       ts(rand(0..30))
  }

  # Course purchases (1-3)
  rand(1..3).times do
    tx_rows << {
      wallet_id:        wid,
      amount:           rand(50_000..499_000),
      transaction_type: 1,   # debit
      source_type:      'enrollment',
      source_id:        rand(1..1000),
      created_at:       ts(rand(1..300)),
      updated_at:       ts(rand(0..10))
    }
  end
end

# Instructors: receive earnings (credit)
instructor_ids.sample(80).each do |uid|
  wid = wallet_id_map[uid]
  next unless wid

  rand(2..8).times do
    tx_rows << {
      wallet_id:        wid,
      amount:           rand(50_000..2_000_000),
      transaction_type: 0,   # credit (earnings)
      source_type:      'enrollment_revenue',
      source_id:        rand(1..5000),
      created_at:       ts(rand(1..365)),
      updated_at:       ts(rand(0..10))
    }
  end
end

batch_insert(WalletTransaction, tx_rows)
ok(WalletTransaction.count, 'wallet_transactions')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15F: PAYOUT REQUESTS
# ─────────────────────────────────────────────────────────────────────────────
step '(15f/16) Creating payout requests'

approved_insts = InstructorProfile.where(status: 'approved').pluck(:user_id)
payout_rows    = []

PAYOUT_STATUSES = { 0 => 'pending', 1 => 'approved', 2 => 'rejected' }

approved_insts.sample(60).each_with_index do |uid, i|
  prof = InstructorProfile.find_by(user_id: uid)
  rand(1..3).times do |pi|
    status = [0, 1, 1, 1, 2].sample   # mostly approved
    payout_rows << {
      user_id:           uid,
      amount:            rand(200_000..5_000_000),
      status:            status,
      note:              status == 2 ? 'Thông tin ngân hàng không hợp lệ, vui lòng cập nhật.' : nil,
      bank_name:         prof&.bank_name || 'Vietcombank',
      bank_account_num:  prof&.bank_account_number || "1234#{(uid * 7 + pi).to_s.rjust(8, '0')}",
      bank_account_name: User.find(uid).name,
      created_at:        ts(rand(10..365)),
      updated_at:        ts(rand(0..30))
    }
  end
end

batch_insert(PayoutRequest, payout_rows)
ok(PayoutRequest.count, 'payout_requests')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15G: NOTIFICATIONS
# ─────────────────────────────────────────────────────────────────────────────
step '(15g/16) Creating notifications'

NOTIF_TYPES = %w[enrollment review comment course_update quiz_result certificate].freeze
NOTIF_TITLES = {
  'enrollment'    => 'Đăng ký khóa học thành công',
  'review'        => 'Có đánh giá mới cho khóa học của bạn',
  'comment'       => 'Bình luận mới trong bài học của bạn',
  'course_update' => 'Khóa học bạn theo dõi vừa được cập nhật',
  'quiz_result'   => 'Kết quả bài kiểm tra đã sẵn sàng',
  'certificate'   => 'Chứng chỉ hoàn thành khóa học đã được cấp',
}.freeze
NOTIF_BODIES = {
  'enrollment'    => 'Bạn đã đăng ký thành công. Bắt đầu học ngay!',
  'review'        => 'Một học viên vừa để lại đánh giá 5 sao cho khóa học của bạn.',
  'comment'       => 'Có câu hỏi mới đang chờ bạn trả lời.',
  'course_update' => 'Instructor vừa thêm 3 bài học mới vào khóa học.',
  'quiz_result'   => 'Bạn đạt 85/100 điểm. Chúc mừng, bạn đã vượt ngưỡng pass!',
  'certificate'   => 'Tải chứng chỉ của bạn và chia sẻ lên LinkedIn ngay nhé!',
}.freeze

notif_rows = []

# 3–8 notifications per active student and per instructor
(active_student_ids.sample(1500) + instructor_ids.sample(100)).each do |uid|
  rand(3..8).times do |ni|
    ntype   = NOTIF_TYPES[ni % NOTIF_TYPES.size]
    days_ago = rand(1..180)
    notif_rows << {
      user_id:           uid,
      title:             NOTIF_TITLES[ntype],
      body:              NOTIF_BODIES[ntype],
      notification_type: ntype,
      read_at:           rand < 0.55 ? ts(days_ago) : nil,
      actionable_type:   'Course',
      actionable_id:     all_course_ids.sample,
      created_at:        ts(days_ago),
      updated_at:        ts(rand(0..days_ago))
    }
  end
end

batch_insert(Notification, notif_rows)
ok(Notification.count, 'notifications')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15H: COURSE SIMILARITIES
# ─────────────────────────────────────────────────────────────────────────────
step '(15h/16) Creating course similarities'

sim_rows = []
sim_seen = Set.new

# For each of the top 60 popular courses, create 5–8 similarity pairs
all_course_ids.first(60).each do |cid_a|
  all_course_ids.sample(rand(5..8)).each do |cid_b|
    next if cid_a == cid_b
    key = [cid_a, cid_b].sort.join(',')
    next if sim_seen.include?(key)
    sim_seen.add(key)

    # Ensure course_a_id < course_b_id to respect the unique index convention
    a, b = [cid_a, cid_b].minmax
    sim_rows << {
      course_a_id: a,
      course_b_id: b,
      score:       rand(0.500000..0.990000).round(6),
      computed_at: ts(rand(1..30)),
      created_at:  ts(rand(1..30)),
      updated_at:  ts(rand(0..10))
    }
  end
end

batch_insert(CourseSimilarity, sim_rows)
ok(CourseSimilarity.count, 'course_similarities')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15I: USER RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────────────────────
step '(15i/16) Creating user recommendations'

REASON_TYPES = %w[collaborative content_based popular trending similar_learners].freeze

rec_rows = []
rec_seen = Set.new

# VIP and active students (top 800) get personalized recommendations
active_student_ids.first(800).each do |uid|
  enrolled = (enrolled_courses_per_user[uid] || []).to_set

  # Recommend 5–10 courses they haven't enrolled in
  candidates = all_course_ids.reject { |cid| enrolled.include?(cid) }
  candidates.sample(rand(5..10)).each do |cid|
    key = [uid, cid]
    next if rec_seen.include?(key)
    rec_seen.add(key)

    rec_rows << {
      user_id:     uid,
      course_id:   cid,
      score:       rand(0.6000..0.9999).round(4),
      reason_type: REASON_TYPES.sample,
      computed_at: ts(rand(1..14)),
      created_at:  ts(rand(1..14)),
      updated_at:  ts(rand(0..7))
    }
  end
end

batch_insert(UserRecommendation, rec_rows)
ok(UserRecommendation.count, 'user_recommendations')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15J: MESSAGE REACTIONS
# ─────────────────────────────────────────────────────────────────────────────
step '(15j/16) Creating message reactions'

EMOJIS = %w[👍 ❤️ 🎉 😂 🔥 👏 💡 ✅].freeze

reaction_rows = []
reaction_seen = Set.new

msg_ids = DiscussionMessage.order(:id).pluck(:id, :course_id)
msg_ids.sample(300).each do |mid, cid|
  reactors = (enrolled_per_course[cid] || []).sample(rand(1..5))
  reactors.each do |uid|
    emoji = EMOJIS.sample
    key   = [uid, mid, emoji]
    next if reaction_seen.include?(key)
    reaction_seen.add(key)
    reaction_rows << {
      user_id:               uid,
      discussion_message_id: mid,
      emoji:                 emoji,
      created_at:            ts(rand(1..60)),
      updated_at:            ts(rand(0..10))
    }
  end
end

batch_insert(MessageReaction, reaction_rows)
ok(MessageReaction.count, 'message_reactions')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15K: LICENSES + INVOICES (B2B)
# ─────────────────────────────────────────────────────────────────────────────
step '(15k/16) Creating B2B licenses & invoices'

# ZigEXn buys licenses for a set of courses for their 10 users
b2b_course_ids = all_course_ids.sample(20)   # 20 licensed courses
license_rows   = []
invoice_rows   = []
inv_num_seq    = 1

b2b_course_ids.each do |cid|
  price = course_prices[cid] || 299_000
  qty   = b2b_user_ids.size   # 10 users per course
  paid_at_days = rand(30..180)

  # Invoice per course
  invoice_rows << {
    organization_id:        org.id,
    course_id:              cid,
    quantity:               qty,
    unit_price:             price,
    total_amount:           (price * qty).round(2),
    stripe_session_id:      "cs_live_#{SecureRandom.hex(16)}",
    stripe_payment_intent:  "pi_#{SecureRandom.hex(16)}",
    status:                 1,   # paid
    invoice_number:         "INV-ZIGEXN-#{inv_num_seq.to_s.rjust(4, '0')}",
    paid_at:                ts(paid_at_days),
    created_at:             ts(paid_at_days + 1),
    updated_at:             ts(paid_at_days)
  }
  inv_num_seq += 1

  # Licenses per user
  b2b_user_ids.each do |uid|
    license_rows << {
      organization_id: org.id,
      course_id:       cid,
      user_id:         uid,
      code:            "LIC-#{SecureRandom.hex(8).upcase}",
      status:          1,   # active
      price:           price,
      expires_at:      (SEED_NOW + 365.days).strftime('%Y-%m-%d %H:%M:%S'),
      created_at:      ts(paid_at_days),
      updated_at:      ts(rand(0..paid_at_days))
    }
  end
end

License.insert_all(license_rows) unless license_rows.empty?
Invoice.insert_all(invoice_rows) unless invoice_rows.empty?
ok(License.count, 'licenses')
ok(Invoice.count, 'invoices')

# ─────────────────────────────────────────────────────────────────────────────
# STEP 16: FINAL ACTIVATION
# ─────────────────────────────────────────────────────────────────────────────
step '(16/16) Activating all user accounts'

User.update_all(confirmed_at: SEED_NOW)
ok(User.count, 'users confirmed')

# ── Final summary ─────────────────────────────────────────────────────────────
puts "\n" + "─" * 72
puts "  SEED COMPLETE in #{elapsed}s"
puts "─" * 72
puts "  %-30s %8d" % ['Users',               User.count]
puts "  %-30s %8d" % ['Organizations',        Organization.count]
puts "  %-30s %8d" % ['Categories',           Category.count]
puts "  %-30s %8d" % ['Courses',              Course.count]
puts "  %-30s %8d" % ['Modules',              CourseModule.count]
puts "  %-30s %8d" % ['Lessons',              Lesson.count]
puts "  %-30s %8d" % ['Quizzes',              Quiz.count]
puts "  %-30s %8d" % ['Questions',            Question.count]
puts "  %-30s %8d" % ['Question Options',     QuestionOption.count]
puts "  %-30s %8d" % ['Quiz Questions',       QuizQuestion.count]
puts "  %-30s %8d" % ['Enrollments',          Enrollment.count]
puts "  %-30s %8d" % ['Progress Trackings',   ProgressTracking.count]
puts "  %-30s %8d" % ['Reviews',              Review.count]
puts "  %-30s %8d" % ['Quiz Attempts',        QuizAttempt.count]
puts "  %-30s %8d" % ['Quiz Answers',         QuizAnswer.count]
puts "  %-30s %8d" % ['Certificates',         Certificate.count]
puts "  %-30s %8d" % ['Comments',             Comment.count]
puts "  %-30s %8d" % ['Discussion Posts',     DiscussionPost.count]
puts "  %-30s %8d" % ['Discussion Replies',   DiscussionReply.count]
puts "  %-30s %8d" % ['Discussion Messages',  DiscussionMessage.count]
puts "  %-30s %8d" % ['Notes',               Note.count]
puts "  %-30s %8d" % ['Wishlists',            Wishlist.count]
puts "  %-30s %8d" % ['Carts',               Cart.count]
puts "  %-30s %8d" % ['Cart Items',           CartItem.count]
puts "  %-30s %8d" % ['Coupons',              Coupon.count]
puts "  %-30s %8d" % ['Wallet Transactions',  WalletTransaction.count]
puts "  %-30s %8d" % ['Payout Requests',      PayoutRequest.count]
puts "  %-30s %8d" % ['Notifications',        Notification.count]
puts "  %-30s %8d" % ['Course Similarities',  CourseSimilarity.count]
puts "  %-30s %8d" % ['User Recommendations', UserRecommendation.count]
puts "  %-30s %8d" % ['Message Reactions',    MessageReaction.count]
puts "  %-30s %8d" % ['Licenses',             License.count]
puts "  %-30s %8d" % ['Invoices',             Invoice.count]
puts "─" * 72
puts "  Demo credentials:"
puts "    Admin:      admin@edtech.dev / Demo@12345!"
puts "    Instructor: nguyen.minh.duc@gmail.com / Demo@12345!"
puts "    Student:    (any student email) / Demo@12345!"
puts "    B2B:        learning-admin@zigexn.vn / Demo@12345!"
puts "─" * 72
$stdout.flush
