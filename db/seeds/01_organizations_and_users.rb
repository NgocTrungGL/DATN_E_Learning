# frozen_string_literal: true
# db/seeds/01_organizations_and_users.rb

module SeedOrganizationsAndUsers
  include SeedHelpers

  def self.run!
    # ── Organization ────────────────────────────────────────
    org = Organization.find_or_create_by!(domain: 'zigexn.jp') do |o|
      o.name = 'ZIGExN Co., Ltd.'
      o.plan = 2
      o.created_at = SeedHelpers::NOW
      o.updated_at = SeedHelpers::NOW
    end
    puts "  ✓ Organization: #{org.name}"

    # ── Users ────────────────────────────────────────────────
    now = SeedHelpers::NOW
    SeedHelpers.used_emails.merge(User.pluck(:email))

    users_batch      = []
    profiles_batch   = []
    instructor_batch = []

    # --- Admin ---
    admin_email = 'admin@edunext.vn'
    unless SeedHelpers.used_emails.include?(admin_email)
      users_batch << build_user('Nguyễn Minh Đức', admin_email, 'admin', 2.years.ago)
    end

    # --- B2B org admin ---
    org_email = 'learning-admin@zigexn.jp'
    unless SeedHelpers.used_emails.include?(org_email)
      users_batch << build_user('Tanaka Hiroshi', org_email, 'company_admin',
                                14.months.ago, organization_id: org.id)
    end

    # --- Second B2B contact ---
    org_email2 = 'hr.training@zigexn.jp'
    unless SeedHelpers.used_emails.include?(org_email2)
      users_batch << build_user('Suzuki Kenji', org_email2, 'student',
                                13.months.ago, organization_id: org.id)
    end

    # --- Instructors (100) ---
    100.times do |i|
      data = case i % 4
             when 0 then SeedHelpers.vn_name(male: i.even?)
             when 1 then SeedHelpers.jp_name
             when 2 then SeedHelpers.en_name
             else        SeedHelpers.kr_name
             end
      email    = SeedHelpers.unique_email(data[:slug])
      created  = SeedHelpers.rand_time(SeedHelpers::THREE_YRS_AGO, 2.years.ago)
      users_batch << build_user(data[:name], email, 'instructor', created)
    end

    # --- Students (950) ---
    950.times do |i|
      data = case i % 10
             when 0..4 then SeedHelpers.vn_name(male: i.odd?)
             when 5..6 then SeedHelpers.jp_name
             when 7..8 then SeedHelpers.en_name
             else           SeedHelpers.kr_name
             end
      email   = SeedHelpers.unique_email(data[:slug])
      created = SeedHelpers.rand_time(SeedHelpers::THREE_YRS_AGO, 3.months.ago)
      org_id  = (i < 25) ? org.id : nil
      users_batch << build_user(data[:name], email, 'student', created, organization_id: org_id)
    end

    User.insert_all!(users_batch)
    puts "  ✓ #{users_batch.length} users created"

    # ── Profiles ────────────────────────────────────────────
    all_users = User.all.order(:id).to_a
    all_users.each do |u|
      profiles_batch << {
        user_id: u.id,
        bio:     (u.role == 'instructor' ? SeedHelpers::INSTRUCTOR_BIOS : SeedHelpers::STUDENT_BIOS).sample,
        phone:   "+84#{rand(900_000_000..999_999_999)}",
        gender:  %w[male female].sample,
        dob:     SeedHelpers.rand_date(40.years.ago, 18.years.ago),
        created_at: u.created_at,
        updated_at: u.updated_at,
      }
    end
    Profile.insert_all!(profiles_batch)
    puts "  ✓ #{profiles_batch.length} profiles created"

    # ── Instructor profiles ─────────────────────────────────
    instructors = all_users.select { |u| u.role == 'instructor' }
    instructors.each_with_index do |u, i|
      instructor_batch << {
        user_id:            u.id,
        bio_detailed:       SeedHelpers::INSTRUCTOR_BIOS[i % SeedHelpers::INSTRUCTOR_BIOS.length],
        linkedin_url:       linkedin_url(u.name),
        cv_url:             "https://storage.edunext.vn/cvs/instructor_#{u.id}.pdf",
        website_url:        SeedHelpers.chance(40) ? "https://#{u.name.downcase.gsub(/[^a-z]/, '').first(12)}.dev" : nil,
        bank_name:          SeedHelpers::BANKS.sample,
        bank_account_number: rand(1_000_000_000..9_999_999_999).to_s,
        bank_account_name:  u.name.upcase,
        status:             'approved',
        phone:              "+84#{rand(900_000_000..999_999_999)}",
        admin_note:         SeedHelpers.chance(30) ? 'Verified instructor with industry experience.' : nil,
        created_at:         u.created_at,
        updated_at:         u.updated_at,
      }
    end
    InstructorProfile.insert_all!(instructor_batch)
    puts "  ✓ #{instructor_batch.length} instructor profiles created"

    # ── Wallets ──────────────────────────────────────────────
    wallets_batch = all_users.map do |u|
      balance = case u.role
                when 'instructor' then rand(1_000_000..80_000_000)
                when 'admin'      then 0
                else                   rand(0..10_000_000)
                end
      { user_id: u.id, balance: balance, created_at: u.created_at, updated_at: now }
    end
    Wallet.insert_all!(wallets_batch)
    puts "  ✓ #{wallets_batch.length} wallets created"
  end

  # ── Private helpers ───────────────────────────────────────
  def self.build_user(name, email, role, created_at, organization_id: nil)
    now = Time.current
    SeedHelpers.used_emails.add(email)
    {
      name:                  name,
      email:                 email,
      encrypted_password:    SeedHelpers::SEED_PASSWORD,
      role:                  role,
      avatar_url:            SeedHelpers.avatar(name),
      organization_id:       organization_id,
      confirmed_at:          created_at + rand(1..48).hours,
      confirmation_sent_at:  created_at,
      created_at:            created_at,
      updated_at:            SeedHelpers.rand_time(created_at, now),
    }
  end
  private_class_method :build_user

  def self.linkedin_url(name)
    slug = name.downcase.unicode_normalize(:nfd).gsub(/[^a-z0-9\s]/, '').strip.gsub(/\s+/, '-')
    "https://linkedin.com/in/#{slug}"
  end
  private_class_method :linkedin_url
end
