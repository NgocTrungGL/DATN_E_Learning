# frozen_string_literal: true
# db/seeds/05_enrollments.rb

module SeedEnrollments
  def self.run!
    now        = SeedHelpers::NOW
    students   = User.where(role: 'student').order(:id).to_a
    courses    = Course.published.order(:id).to_a
    org_users  = User.where.not(organization_id: nil).to_a
    org        = Organization.first

    enrolled_pairs = Set.new
    enrollments_batch = []

    # ── Popularity weights (power-law distribution) ──────────
    # First 10% of courses get ~40% of traffic (popular courses)
    course_weights = courses.each_with_index.map do |c, i|
      weight = if i < courses.size * 0.1
                 rand(80..150)    # Very popular
               elsif i < courses.size * 0.3
                 rand(40..79)     # Popular
               elsif i < courses.size * 0.6
                 rand(15..39)     # Average
               else
                 rand(2..14)      # Niche
               end
      [c, weight]
    end

    # Build weighted pool
    weighted_pool = course_weights.flat_map { |c, w| Array.new(w, c) }

    # ── Enroll students: each student takes 2–12 courses ─────
    students.each do |student|
      course_count = case rand(10)
                     when 0..2 then rand(1..2)    # Light learner
                     when 3..6 then rand(3..6)    # Regular
                     when 7..8 then rand(7..10)   # Active
                     else           rand(10..15)  # Power user
                     end

      selected = weighted_pool.sample(course_count * 3).uniq.first(course_count)

      selected.each do |course|
        key = [student.id, course.id]
        next if enrolled_pairs.include?(key)
        enrolled_pairs.add(key)

        enrolled_at = SeedHelpers.rand_time(
          [student.created_at, course.created_at].max,
          now
        )

        # Status distribution
        status = case rand(10)
                 when 0 then 'pending'
                 when 1..2 then 'completed'
                 else 'active'
                 end

        enrollments_batch << {
          user_id:     student.id,
          course_id:   course.id,
          enrolled_at: enrolled_at,
          status:      status,
          price:       course.price,
          created_at:  enrolled_at,
          updated_at:  SeedHelpers.rand_time(enrolled_at, now),
        }
      end

      # Batch flush
      if enrollments_batch.size >= 2000
        Enrollment.insert_all(enrollments_batch)
        enrollments_batch = []
      end
    end

    # ── B2B org enrollments via licenses ─────────────────────
    if org_users.any? && courses.any?
      org_courses = courses.sample(15)  # Org bought licenses for 15 courses
      licenses_batch  = []
      invoices_batch  = []

      org_courses.each_with_index do |course, i|
        quantity   = rand(5..25)
        unit_price = [course.price * 0.85, 99_000_000.0 / quantity].min.round(2)  # 15% org discount

        invoice_num = "INV-ZGX-#{2024}-#{(i + 1).to_s.rjust(4, '0')}"
        paid_at     = SeedHelpers.rand_time(14.months.ago, 6.months.ago)

        invoices_batch << {
          organization_id:       org.id,
          course_id:             course.id,
          quantity:              quantity,
          unit_price:            unit_price,
          total_amount:          unit_price * quantity,
          stripe_session_id:     "cs_live_#{SecureRandom.hex(20)}",
          stripe_payment_intent: "pi_#{SecureRandom.hex(16)}",
          status:                1,  # paid
          invoice_number:        invoice_num,
          paid_at:               paid_at,
          created_at:            paid_at,
          updated_at:            paid_at,
        }

        # Create licenses
        org_users.first(quantity).each do |org_user|
          key = [org_user.id, course.id]
          unless enrolled_pairs.include?(key)
            enrolled_pairs.add(key)

            enrolled_at = SeedHelpers.rand_time(paid_at, now)
            enrollments_batch << {
              user_id:     org_user.id,
              course_id:   course.id,
              enrolled_at: enrolled_at,
              status:      'active',
              price:       unit_price,
              created_at:  enrolled_at,
              updated_at:  enrolled_at,
            }
          end

          licenses_batch << {
            organization_id: org.id,
            course_id:       course.id,
            user_id:         org_user.id,
            code:            SecureRandom.alphanumeric(16).upcase,
            status:          1,  # used
            price:           unit_price,
            expires_at:      1.year.from_now,
            created_at:      paid_at,
            updated_at:      paid_at,
          }
        end
      end

      Invoice.insert_all!(invoices_batch)
      License.insert_all!(licenses_batch) if licenses_batch.any?
      puts "  ✓ #{invoices_batch.length} B2B invoices, #{licenses_batch.length} licenses"
    end

    Enrollment.insert_all(enrollments_batch) if enrollments_batch.any?

    # ── Wishlists ────────────────────────────────────────────
    wishlist_pairs  = Set.new
    wishlists_batch = []

    students.sample(400).each do |student|
      rand(1..5).times do
        course = courses.sample
        key    = [student.id, course.id]
        next if wishlist_pairs.include?(key) || enrolled_pairs.include?(key)
        wishlist_pairs.add(key)
        added = SeedHelpers.rand_time(student.created_at, now)
        wishlists_batch << {
          user_id:    student.id,
          course_id:  course.id,
          created_at: added,
          updated_at: added,
        }
      end
    end
    Wishlist.insert_all(wishlists_batch)

    puts "  ✓ #{Enrollment.count} enrollments, #{Wishlist.count} wishlists"

    # ── Coupons ──────────────────────────────────────────────
    instructors = User.where(role: 'instructor').to_a
    coupons_batch = []
    [
      { code: 'SUMMER2024', discount_type: 0, discount_value: 20, target_type: 0 },
      { code: 'NEWUSER15',  discount_type: 0, discount_value: 15, target_type: 0 },
      { code: 'FLASH50K',   discount_type: 1, discount_value: 50_000, target_type: 0 },
      { code: 'ZIGEXN30',   discount_type: 0, discount_value: 30, target_type: 0 },
      { code: 'TECH2024',   discount_type: 0, discount_value: 25, target_type: 0 },
      { code: 'JP100K',     discount_type: 1, discount_value: 100_000, target_type: 0 },
      { code: 'EARLYBIRD',  discount_type: 0, discount_value: 40, target_type: 0 },
      { code: 'WELCOME10',  discount_type: 0, discount_value: 10, target_type: 0 },
    ].each do |c|
      next if Coupon.exists?(code: c[:code])
      coupons_batch << c.merge(
        creator_id:   instructors.sample.id,
        usage_limit:  rand(50..500),
        usage_count:  rand(0..100),
        status:       0,
        start_at:     6.months.ago,
        end_at:       6.months.from_now,
        created_at:   6.months.ago,
        updated_at:   now,
      )
    end
    Coupon.insert_all(coupons_batch) if coupons_batch.any?
    puts "  ✓ #{Coupon.count} coupons"

    # ── Payout requests ──────────────────────────────────────
    payouts_batch = []
    instructors.sample(30).each do |inst|
      rand(1..4).times do
        requested_at = SeedHelpers.rand_time(18.months.ago, 1.month.ago)
        payouts_batch << {
          user_id:          inst.id,
          amount:           rand(1_000_000..20_000_000),
          status:           [0, 1, 1, 2].sample,  # pending, approved, rejected
          note:             ['Thanh toán tháng này', 'Monthly payout request', nil].sample,
          bank_name:        SeedHelpers::BANKS.sample,
          bank_account_num: rand(1_000_000_000..9_999_999_999).to_s,
          bank_account_name: inst.name.upcase,
          created_at:       requested_at,
          updated_at:       SeedHelpers.rand_time(requested_at, now),
        }
      end
    end
    PayoutRequest.insert_all(payouts_batch)
    puts "  ✓ #{payouts_batch.length} payout requests"

    # ── Subscriptions (premium members) ─────────────────────
    subs_batch = []
    students.sample(80).each do |student|
      next if Subscription.exists?(user_id: student.id)
      start_t = SeedHelpers.rand_time(18.months.ago, 3.months.ago)
      subs_batch << {
        user_id:               student.id,
        plan_type:             [0, 1].sample,  # 0=monthly, 1=annual
        status:                'active',
        stripe_subscription_id: "sub_#{SecureRandom.hex(12)}",
        stripe_customer_id:    "cus_#{SecureRandom.hex(12)}",
        current_period_start:  start_t,
        current_period_end:    start_t + 1.year,
        created_at:            start_t,
        updated_at:            now,
      }
    end
    Subscription.insert_all(subs_batch)
    puts "  ✓ #{subs_batch.length} subscriptions"
  end
end
