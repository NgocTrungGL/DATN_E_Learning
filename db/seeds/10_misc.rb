# frozen_string_literal: true
# db/seeds/10_misc.rb

module SeedMisc
  DISCUSSION_TOPICS = [
    "Cách tối ưu hiệu suất khi xử lý dataset lớn?",
    "So sánh ưu nhược điểm của hai approach trong bài học này",
    "Ai có thể giải thích lại phần này bằng ngôn ngữ đơn giản hơn không?",
    "Tôi gặp lỗi khi chạy đoạn code ở phút 18:30 — ai biết cách fix không?",
    "Theo mọi người, pattern nào phù hợp hơn cho production?",
    "Chia sẻ project của mình sau khi học xong module này",
    "Best practices khi áp dụng vào dự án thực tế là gì?",
    "Tài liệu nào nên đọc thêm bên cạnh course này?",
    "Hỏi về sự khác nhau giữa hai khái niệm được đề cập",
    "Tips để ghi nhớ và không bị quên kiến thức sau khi học?",
  ].freeze

  DISCUSSION_REPLIES_POOL = [
    "Cảm ơn bạn đã đặt câu hỏi! Tôi cũng thắc mắc về điều này.",
    "Theo kinh nghiệm của mình thì approach thứ hai hiệu quả hơn trong production.",
    "Bạn có thể share error message cụ thể không? Mình sẽ cố giúp.",
    "Instructor đã giải thích điều này trong phần Q&A. Bạn có thể check lại.",
    "Mình đã làm project tương tự và dùng cách này, hoạt động tốt lắm.",
    "Đây là link tài liệu mình thấy hữu ích: official docs luôn là điểm xuất phát tốt.",
    "Sau khi thử cả hai cách, mình thấy cách trong video clean hơn về long term.",
  ].freeze

  CHAT_MESSAGES = [
    "Chào mọi người! Mình mới bắt đầu học course này.",
    "Ai đang học phần Advanced cùng mình không?",
    "Phần này khó quá, mình phải xem đi xem lại mấy lần.",
    "Vừa áp dụng vào project thật, kết quả rất tốt!",
    "Cảm ơn instructor và cộng đồng vì đã hỗ trợ nhiệt tình.",
    "Mình làm xong bài tập rồi, ai cần code review không?",
    "Tip nhỏ: nên đọc docs chính thức song song với course này.",
  ].freeze

  EMOJIS = %w[👍 ❤️ 🔥 💡 👏 🙏 ✅].freeze

  def self.run!
    now        = SeedHelpers::NOW
    students   = User.where(role: 'student').to_a
    enrollments = Enrollment.where(status: %w[active completed]).includes(:course).to_a

    # ── Discussion posts ─────────────────────────────────────
    posts_batch   = []
    replies_batch = []

    enrollments.sample(500).each do |en|
      next unless SeedHelpers.chance(30)
      created_at = SeedHelpers.rand_time(en.enrolled_at, now)

      posts_batch << {
        course_id:    en.course_id,
        user_id:      en.user_id,
        title:        DISCUSSION_TOPICS.sample,
        content:      "#{DISCUSSION_TOPICS.sample} Mình đang học course này và muốn nghe ý kiến từ cộng đồng.",
        pinned:       SeedHelpers.chance(5),
        locked:       false,
        replies_count: 0,
        created_at:   created_at,
        updated_at:   created_at,
      }
    end

    DiscussionPost.insert_all(posts_batch) if posts_batch.any?
    puts "  ✓ #{posts_batch.length} discussion posts"

    # Add replies to posts
    all_posts = DiscussionPost.order(Arel.sql('RANDOM()')).limit(200).to_a
    all_posts.each do |post|
      reply_count = rand(0..6)
      reply_count.times do |ri|
        replied_at = SeedHelpers.rand_time(post.created_at, now)
        replies_batch << {
          discussion_post_id: post.id,
          user_id:            students.sample.id,
          content:            DISCUSSION_REPLIES_POOL.sample,
          parent_id:          nil,
          created_at:         replied_at,
          updated_at:         replied_at,
        }
      end
    end
    DiscussionReply.insert_all(replies_batch) if replies_batch.any?
    puts "  ✓ #{replies_batch.length} discussion replies"

    # Update replies_count
    all_posts.each do |post|
      count = DiscussionReply.where(discussion_post_id: post.id).count
      DiscussionPost.where(id: post.id).update_all(replies_count: count) if count > 0
    end

    # ── Discussion messages (live chat per course) ────────────
    messages_batch   = []
    reactions_batch  = []

    Course.published.order(Arel.sql('RANDOM()')).limit(80).each do |course|
      enrolled_users = Enrollment.where(course_id: course.id).pluck(:user_id)
      next if enrolled_users.empty?

      msg_count = rand(5..25)
      parent_ids = []

      msg_count.times do |mi|
        user_id    = enrolled_users.sample
        created_at = SeedHelpers.rand_time(course.created_at, now)
        parent_id  = (parent_ids.any? && SeedHelpers.chance(30)) ? parent_ids.sample : nil

        messages_batch << {
          course_id:    course.id,
          user_id:      user_id,
          content:      CHAT_MESSAGES.sample,
          parent_id:    parent_id,
          replies_count: 0,
          created_at:   created_at,
          updated_at:   created_at,
        }
        parent_ids << messages_batch.size  # track index
      end
    end

    DiscussionMessage.insert_all(messages_batch) if messages_batch.any?
    puts "  ✓ #{messages_batch.length} discussion messages"

    # Add emoji reactions
    all_messages = DiscussionMessage.order(Arel.sql('RANDOM()')).limit(500).pluck(:id)
    seen_reactions = Set.new
    all_messages.each do |msg_id|
      rand(1..5).times do
        user_id = students.sample.id
        emoji   = EMOJIS.sample
        key     = [user_id, msg_id, emoji]
        next if seen_reactions.include?(key)
        seen_reactions.add(key)
        ts = now
        reactions_batch << {
          user_id:               user_id,
          discussion_message_id: msg_id,
          emoji:                 emoji,
          created_at:            ts,
          updated_at:            ts,
        }
      end
    end
    MessageReaction.insert_all(reactions_batch) if reactions_batch.any?
    puts "  ✓ #{reactions_batch.length} message reactions"

    # ── Study plans ───────────────────────────────────────────
    # Skipped for local seed speed.
    puts "  - study plans skipped"

    # ── Course similarities (for recommendations) ─────────────
    courses     = Course.published.order(:id).pluck(:id)
    sims_batch  = []
    seen_sims   = Set.new

    courses.first(100).each do |cid|
      courses.sample(8).each do |other_cid|
        next if cid == other_cid
        pair = [cid, other_cid].minmax
        next if seen_sims.include?(pair)
        seen_sims.add(pair)
        sims_batch << {
          course_a_id: pair[0],
          course_b_id: pair[1],
          score:       rand(0.3..0.98).round(6),
          computed_at: now,
          created_at:  now,
          updated_at:  now,
        }
      end
    end
    CourseSimilarity.insert_all(sims_batch) if sims_batch.any?
    puts "  ✓ #{sims_batch.length} course similarity scores"

    # ── User recommendations ──────────────────────────────────
    recs_batch  = []
    seen_recs   = Set.new
    reason_types = %w[similar_enrolled category_interest top_rated trending].freeze

    students.sample(300).each do |user|
      enrolled_ids = Enrollment.where(user_id: user.id).pluck(:course_id)
      recommended  = courses.reject { |cid| enrolled_ids.include?(cid) }.sample(5)

      recommended.each do |cid|
        key = [user.id, cid]
        next if seen_recs.include?(key)
        seen_recs.add(key)
        recs_batch << {
          user_id:     user.id,
          course_id:   cid,
          score:       rand(0.5..1.0).round(4),
          reason_type: reason_types.sample,
          computed_at: now,
          created_at:  now,
          updated_at:  now,
        }
      end
    end
    UserRecommendation.insert_all(recs_batch) if recs_batch.any?
    puts "  ✓ #{recs_batch.length} user recommendations"

    # ── Carts (active shopping carts) ─────────────────────────
    carts_batch = []
    cart_items_batch = []
    enrolled_map = Enrollment.group(:user_id).pluck(:user_id, Arel.sql('ARRAY_AGG(course_id)'))
                             .to_h rescue {}

    students.sample(120).each do |user|
      cart = Cart.find_or_create_by!(user_id: user.id) do |c|
        c.promo_code = SeedHelpers.chance(20) ? %w[NEWUSER15 WELCOME10 TECH2024].sample : nil
        c.created_at = SeedHelpers.rand_time(user.created_at, now)
        c.updated_at = now
      end

      enrolled_ids = (enrolled_map[user.id] || [])
      candidates   = courses.reject { |cid| enrolled_ids.include?(cid) }.sample(rand(1..3))
      candidates.each do |cid|
        next if CartItem.exists?(cart_id: cart.id, course_id: cid)
        added = SeedHelpers.rand_time(cart.created_at, now)
        cart_items_batch << {
          cart_id:    cart.id,
          course_id:  cid,
          created_at: added,
          updated_at: added,
        }
      end
    end

    CartItem.insert_all(cart_items_batch) if cart_items_batch.any?
    puts "  ✓ #{Cart.count} carts, #{CartItem.count} cart items"
  end
end
