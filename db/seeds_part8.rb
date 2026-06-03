# =============================================================================
# PART 8 — Comments · Discussion Posts · Discussion Replies · Messages
# =============================================================================

# ── Re-query state ────────────────────────────────────────────────────────────
instructor_ids       = User.where(role: 'instructor').order(:id).pluck(:id)
course_instructor    = Course.pluck(:id, :created_by).to_h   # course_id => instructor_id

# Build course → lesson IDs (via modules)
course_mod_ids       = CourseModule.pluck(:id, :course_id)
mod_lesson_ids       = Lesson.pluck(:id, :course_module_id).each_with_object({}) do |(lid, mid), h|
                         (h[mid] ||= []) << lid
                       end
course_lesson_ids    = course_mod_ids.each_with_object({}) do |(mid, cid), h|
                         lids = mod_lesson_ids[mid] || []
                         (h[cid] ||= []).concat(lids)
                       end

# Enrolled users per course (for realistic commenters)
enrolled_per_course  = Enrollment
                         .where(status: %w[active completed])
                         .pluck(:user_id, :course_id)
                         .each_with_object({}) do |(uid, cid), h|
                           (h[cid] ||= []) << uid
                         end

all_course_ids = Course.where(status: :published).pluck(:id)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 13: COMMENTS  (~55,000)
# ─────────────────────────────────────────────────────────────────────────────
step '(13/16) Creating comments (~55,000)'

comment_rows = []

all_course_ids.each do |cid|
  lesson_ids   = course_lesson_ids[cid] || []
  commenters   = enrolled_per_course[cid] || []
  inst_id      = course_instructor[cid]
  next if lesson_ids.empty? || commenters.empty?

  # Each lesson gets 2–6 learner comments; ~30% get an instructor reply
  lesson_ids.each do |lid|
    n_comments = rand(2..6)
    selected_commenters = commenters.sample([n_comments, commenters.size].min)
    days_ago_base = rand(5..365)

    parent_ids = []   # IDs of root comments (for threading) — we assign after insert

    selected_commenters.each_with_index do |uid, i|
      comment_rows << {
        user_id:    uid,
        lesson_id:  lid,
        body:       LEARNER_COMMENTS[(uid.to_i + lid.to_i + i) % LEARNER_COMMENTS.size],
        parent_id:  nil,
        created_at: ts(days_ago_base - i),
        updated_at: ts(rand(0..(days_ago_base - i).clamp(1, days_ago_base)))
      }
    end

    # Instructor reply to the first comment (30% chance)
    if inst_id && rand < 0.30
      comment_rows << {
        user_id:    inst_id,
        lesson_id:  lid,
        body:       INSTRUCTOR_REPLIES[(inst_id.to_i + lid.to_i) % INSTRUCTOR_REPLIES.size],
        parent_id:  nil,   # will be patched after bulk insert using a second pass if desired; nil is valid per schema
        created_at: ts([days_ago_base - 1, 1].max),
        updated_at: ts(rand(0..3))
      }
    end
  end

  # Flush every course to keep memory usage bounded
  if comment_rows.size >= 2000
    batch_insert(Comment, comment_rows)
    comment_rows.clear
  end
end

batch_insert(Comment, comment_rows) unless comment_rows.empty?
ok(Comment.count, 'comments')

# Now patch ~20% of comments to have a parent_id (simulate threaded replies)
# Do this in bulk SQL to avoid AR overhead
step '  └─ Patching threaded replies (parent_id)'

# For each lesson, find the IDs of its first 2 comments and assign later ones to them
Comment.order(:lesson_id, :id).each_slice(2000) do |batch|
  # Group by lesson_id, then assign parent_id for 3rd+ comments at ~25% rate
  by_lesson = batch.group_by(&:lesson_id)
  updates   = []
  by_lesson.each do |_lid, cmts|
    next if cmts.size < 3
    root_ids = cmts.first(2).map(&:id)
    cmts[2..].each do |c|
      next unless rand < 0.25
      updates << [root_ids.sample, c.id]
    end
  end
  updates.each_slice(500) do |upd_batch|
    upd_batch.each do |parent_id, cid|
      Comment.where(id: cid).update_all(parent_id: parent_id)
    end
  end
end

puts "           ✓  threaded replies patched"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 14: DISCUSSIONS
# ─────────────────────────────────────────────────────────────────────────────
step '(14/16) Creating discussion posts, replies & messages'

DISCUSSION_POST_TITLES = [
  'Có ai gặp lỗi này không? Cần giúp đỡ!',
  'Chia sẻ solution bài tập cuối chương',
  'Tổng hợp kiến thức quan trọng của module này',
  'Hỏi về phần exercise ở bài giữa khóa',
  'Resources bổ sung cho chủ đề này',
  'Thảo luận: approach nào tốt hơn?',
  'Tips để nắm vững nội dung phần này nhanh hơn',
  'Project demo của tôi — xin feedback',
  'Câu hỏi phỏng vấn liên quan đến chủ đề này',
  'Tôi đã apply kiến thức này vào công việc như thế nào',
  'Confused about the difference between X and Y',
  'Study group for this course — who wants to join?',
  'My capstone project walkthrough',
  'Best practices I wish I knew before starting',
  'Weekly challenge: share your progress!',
].freeze

DISCUSSION_POST_BODIES = [
  'Mình đang học phần này và gặp vấn đề với bước thứ 3. Mọi người có thể chỉ cho mình cách giải quyết không? Chi tiết lỗi như sau...',
  'Sau khi hoàn thành module, mình đã tổng hợp lại các điểm quan trọng nhất. Hi vọng giúp ích cho mọi người!',
  'Mình vừa apply kiến thức từ bài học này vào dự án thực tế tại công ty và kết quả rất tốt. Muốn chia sẻ kinh nghiệm.',
  'Có ai có thêm resources để đọc về chủ đề này không? Mình muốn đào sâu hơn ngoài nội dung bài giảng.',
  'Mình đang so sánh hai approach được đề cập trong bài. Theo mọi người, approach nào phù hợp với use case X hơn?',
  'Ai đang học cùng phần này không? Mình muốn lập nhóm study group để cùng ôn và giải bài tập.',
  'I just completed this module and wanted to share some insights that might help others. The key takeaway for me was...',
  'Does anyone have experience applying this in production? I have some questions about edge cases.',
  'Sharing my solution to the exercise — would love feedback on my approach. I took a different path than shown in the video.',
  'Just hit a bug I cannot figure out. Error message: TypeError. Any ideas? I\'ve been stuck for 2 hours.',
].freeze

DISCUSSION_REPLY_BODIES = [
  'Cảm ơn bạn đã chia sẻ! Mình cũng gặp vấn đề tương tự và đã giải quyết được bằng cách...',
  'Approach của bạn rất hay! Mình có một gợi ý nhỏ để cải thiện phần X...',
  'Đây chính xác là thông tin mình đang tìm. Cảm ơn rất nhiều!',
  'Bạn có thể giải thích thêm về bước thứ 2 không? Mình chưa rõ lắm.',
  'Great solution! I did it slightly differently but the result is the same.',
  'This thread is super helpful. Bookmarking for future reference.',
  'Mình đã thử cách này và nó hoạt động! Thanks!',
  'Theo mình thì approach kia sẽ tốt hơn trong trường hợp dữ liệu lớn vì...',
  'Đồng ý với bạn! Mình cũng nhận ra điều này sau khi làm dự án thực tế.',
  'Có ai đã push code lên GitHub chưa? Mình muốn xem để so sánh.',
].freeze

DISCUSSION_MSG_BODIES = [
  'Chào mọi người! Mình mới join khóa học này.',
  'Ai đang học phần cuối không? Cùng ôn nhé!',
  'Quiz hôm nay khó quá 😅 Mọi người làm được bao nhiêu câu?',
  'Mình vừa pass bài test! 92 điểm 🎉',
  'Hỏi nhanh: bài này có phần code demo không?',
  'Instructor reply rất nhanh, impressed!',
  'Đang debug cái này từ sáng đến giờ 😭',
  'Tip nhỏ: nếu dùng library phiên bản mới hơn thì cần thêm config này...',
  'Ai có link tài liệu chính thức không? Cần kiểm tra API docs.',
  'Great course so far! The pacing is perfect.',
  'Just joined — excited to learn this topic!',
  'Finished chapter 3. The concepts are clicking now.',
  'Anyone else notice the typo in slide 4? 😄',
  'Recommendation: watch this at 1.25x speed, it flows much better.',
  'The hands-on project at the end made everything click for me.',
].freeze

post_rows    = []
reply_rows   = []
msg_rows     = []

all_course_ids.each do |cid|
  inst_id    = course_instructor[cid]
  commenters = (enrolled_per_course[cid] || []).first(50)   # active learners in this course
  next if commenters.empty?

  # 3–7 discussion posts per course
  n_posts = rand(3..7)
  post_ids_for_course = []

  n_posts.times do |pi|
    poster = [inst_id, commenters.sample].compact.sample
    days_ago = rand(10..300)
    post_rows << {
      course_id:     cid,
      user_id:       poster,
      title:         DISCUSSION_POST_TITLES[(cid.to_i + pi) % DISCUSSION_POST_TITLES.size],
      content:       DISCUSSION_POST_BODIES[(cid.to_i + pi) % DISCUSSION_POST_BODIES.size],
      pinned:        pi == 0 && rand < 0.20,    # 20% chance first post is pinned
      locked:        rand < 0.05,
      replies_count: 0,   # updated after replies inserted
      created_at:    ts(days_ago),
      updated_at:    ts(rand(0..days_ago))
    }
  end

  # 10–25 discussion messages per course
  n_msgs = rand(10..25)
  n_msgs.times do |mi|
    sender = [inst_id, commenters.sample].compact.sample
    days_ago = rand(1..180)
    msg_rows << {
      course_id:     cid,
      user_id:       sender,
      content:       DISCUSSION_MSG_BODIES[(cid.to_i + mi) % DISCUSSION_MSG_BODIES.size],
      parent_id:     nil,
      replies_count: 0,
      created_at:    ts(days_ago),
      updated_at:    ts(rand(0..days_ago))
    }
  end
end

# Insert posts
batch_insert(DiscussionPost, post_rows)
ok(DiscussionPost.count, 'discussion_posts')

# Insert messages
batch_insert(DiscussionMessage, msg_rows)
ok(DiscussionMessage.count, 'discussion_messages')

# Now insert replies (need post IDs)
all_posts = DiscussionPost.order(:id).pluck(:id, :course_id, :user_id)

all_posts.each_slice(200) do |post_slice|
  r_batch = []
  post_slice.each do |post_id, cid, _post_uid|
    commenters = (enrolled_per_course[cid] || []).first(30)
    inst_id    = course_instructor[cid]
    n_replies  = rand(2..6)
    repliers   = ([inst_id] + commenters).compact.sample(n_replies)
    replies_count = 0

    repliers.each_with_index do |ruid, ri|
      r_batch << {
        discussion_post_id: post_id,
        user_id:            ruid,
        content:            DISCUSSION_REPLY_BODIES[(post_id.to_i + ri) % DISCUSSION_REPLY_BODIES.size],
        parent_id:          nil,   # flat for simplicity; nested parent_id requires existing IDs
        created_at:         ts(rand(0..180)),
        updated_at:         ts(rand(0..30))
      }
      replies_count += 1
    end

    # Update replies_count on the post (done in bulk after)
    DiscussionPost.where(id: post_id).update_all(replies_count: replies_count) if replies_count > 0
  end
  DiscussionReply.insert_all(r_batch) unless r_batch.empty?
end

ok(DiscussionReply.count, 'discussion_replies')

# Patch ~15% of messages to have a parent_id (threaded messages)
root_msg_ids = DiscussionMessage.order(:course_id, :id).pluck(:id, :course_id)
  .each_with_object({}) { |(mid, cid), h| (h[cid] ||= []) << mid }

reply_updates = []
root_msg_ids.each do |_cid, ids|
  next if ids.size < 3
  root_ids = ids.first(3)
  ids[3..].each do |mid|
    next unless rand < 0.15
    reply_updates << [root_ids.sample, mid]
  end
end
reply_updates.each_slice(500) do |batch|
  batch.each { |parent_id, mid| DiscussionMessage.where(id: mid).update_all(parent_id: parent_id, replies_count: 1) }
end

puts "           ✓  discussion message threads patched"
