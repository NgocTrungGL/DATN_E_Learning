# frozen_string_literal: true
# db/seeds/09_certificates_and_wallets.rb

module SeedCertificatesAndWallets
  TEMPLATES = %w[classic modern minimalist].freeze

  def self.run!
    now = SeedHelpers::NOW

    # ── Certificates for completed courses ───────────────────
    completed = ProgressTracking.where(
      progress_type: 'course',
      status:        'completed'
    ).to_a

    certs_batch  = []
    seen_certs   = Set.new

    completed.each do |pt|
      key = [pt.user_id, pt.course_id]
      next if seen_certs.include?(key)
      seen_certs.add(key)

      issued = SeedHelpers.rand_time(pt.updated_at, now)
      certs_batch << {
        user_id:          pt.user_id,
        course_id:        pt.course_id,
        certificate_code: "CERT-#{SecureRandom.alphanumeric(10).upcase}",
        issued_at:        issued,
        template_type:    TEMPLATES.sample,
        created_at:       issued,
        updated_at:       issued,
      }
    end

    Certificate.insert_all(certs_batch)
    puts "  ✓ #{certs_batch.length} certificates issued"

    # ── Wallet transactions ──────────────────────────────────
    wallets     = Wallet.all.index_by(&:user_id)
    enrollments = Enrollment.where.not(status: 'pending').to_a

    txns_batch = []

    # Purchase transactions (student pays for course)
    enrollments.each do |en|
      wallet = wallets[en.user_id]
      next unless wallet

      txns_batch << {
        wallet_id:        wallet.id,
        amount:           -(en.price || 0),
        transaction_type: 1,   # 0=credit, 1=debit
        source_type:      'Enrollment',
        source_id:        en.id,
        created_at:       en.enrolled_at,
        updated_at:       en.enrolled_at,
      }

      # Instructor revenue credit
      course     = Course.find_by(id: en.course_id)
      inst_wallet = wallets[course&.created_by]
      next unless inst_wallet

      revenue = ((en.price || 0) * 0.70).round(2)  # 70% rev share
      txns_batch << {
        wallet_id:        inst_wallet.id,
        amount:           revenue,
        transaction_type: 0,   # credit
        source_type:      'Enrollment',
        source_id:        en.id,
        created_at:       en.enrolled_at + 3.days,
        updated_at:       en.enrolled_at + 3.days,
      }

      if txns_batch.size >= 4000
        WalletTransaction.insert_all(txns_batch)
        txns_batch = []
      end
    end

    # Payout transactions
    PayoutRequest.where(status: 1).each do |pr|  # approved payouts
      wallet = wallets[pr.user_id]
      next unless wallet
      txns_batch << {
        wallet_id:        wallet.id,
        amount:           -pr.amount,
        transaction_type: 2,   # payout
        source_type:      'PayoutRequest',
        source_id:        pr.id,
        created_at:       pr.updated_at,
        updated_at:       pr.updated_at,
      }
    end

    WalletTransaction.insert_all(txns_batch) if txns_batch.any?
    puts "  ✓ #{WalletTransaction.count} wallet transactions"

    # ── Notifications ────────────────────────────────────────
    notif_batch = []
    samples     = Enrollment.order(Arel.sql('RANDOM()')).limit(600).to_a

    notification_templates = [
      { title: 'Khóa học mới được thêm vào',       body: 'Một khóa học mới phù hợp với sở thích của bạn vừa được ra mắt.', type: 'new_course' },
      { title: 'Bạn đã hoàn thành khóa học!',      body: 'Chúc mừng! Bạn đã hoàn thành khoá học. Tải chứng chỉ ngay.', type: 'course_complete' },
      { title: 'Nhắc nhở học tập',                 body: 'Bạn chưa học trong 3 ngày. Tiếp tục hành trình nhé!', type: 'learning_reminder' },
      { title: 'Bình luận mới trên bài học của bạn', body: 'Có người đã trả lời câu hỏi của bạn trong phần thảo luận.', type: 'comment_reply' },
      { title: 'Ưu đãi đặc biệt cuối tuần',        body: 'Giảm 40% tất cả khóa học lập trình trong 48 giờ!', type: 'promotion' },
      { title: 'Chứng chỉ sẵn sàng tải về',        body: 'Chứng chỉ hoàn thành khóa học của bạn đã được cấp.', type: 'certificate_ready' },
    ]

    samples.each do |en|
      tmpl       = notification_templates.sample
      created_at = SeedHelpers.rand_time(en.enrolled_at, SeedHelpers::NOW)
      notif_batch << {
        user_id:          en.user_id,
        title:            tmpl[:title],
        body:             tmpl[:body],
        notification_type: tmpl[:type],
        read_at:          SeedHelpers.chance(60) ? SeedHelpers.rand_time(created_at, SeedHelpers::NOW) : nil,
        actionable_type:  'Course',
        actionable_id:    en.course_id,
        created_at:       created_at,
        updated_at:       created_at,
      }
    end

    Notification.insert_all(notif_batch)
    puts "  ✓ #{notif_batch.length} notifications"
  end
end
