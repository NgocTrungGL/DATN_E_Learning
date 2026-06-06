# =============================================================================
# STEP 0: CLEAR DATA
# =============================================================================
step '(0/14) Clearing all tables'

tables_to_truncate = %w[
  message_reactions user_recommendations course_similarities
  discussion_replies discussion_posts discussion_messages
  notes wallet_transactions wallets payout_requests notifications
  cart_items carts wishlists certificates
  quiz_answers quiz_attempts progress_trackings
  reviews enrollments subscriptions licenses invoices
  quiz_questions question_options questions quizzes
  lessons course_modules coupons courses
  instructor_profiles profiles categories users organizations
]

connection = ActiveRecord::Base.connection
case connection.adapter_name.downcase
when /postgres/
  quoted_tables = tables_to_truncate.map { |table| connection.quote_table_name(table) }.join(', ')
  connection.execute("TRUNCATE TABLE #{quoted_tables} RESTART IDENTITY CASCADE")
when /mysql/
  connection.execute('SET FOREIGN_KEY_CHECKS = 0')
  tables_to_truncate.each do |table|
    connection.execute("TRUNCATE TABLE #{connection.quote_table_name(table)}")
  rescue => e
    puts "  Warning truncating #{table}: #{e.message}"
  end
  connection.execute('SET FOREIGN_KEY_CHECKS = 1')
else
  tables_to_truncate.each do |table|
    connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
  rescue => e
    puts "  Warning clearing #{table}: #{e.message}"
  end
end
ok('All tables cleared')

# =============================================================================
# STEP 1: ORGANIZATION
# =============================================================================
step '(1/14) Creating organization'

org = Organization.create!(
  name:   'ZigEXn Corporation',
  domain: 'zigexn.vn',
  plan:   2
)
ok(1, 'organizations')

# =============================================================================
# STEP 2: USERS
# =============================================================================
step '(2/14) Creating users (5,011 total)'

user_rows = []
idx = 0

# ── Admin ──
admin_data = {
  name: 'Admin Hệ thống', email: 'admin@edtech.vn',
  encrypted_password: SEED_PWD, role: 'admin',
  avatar_url: AVATAR_URLS[0],
  confirmed_at: ts(365), created_at: ts(365), updated_at: ts(1),
  confirmation_sent_at: ts(365), confirmation_token: SecureRandom.hex(16),
  organization_id: nil
}
user_rows << admin_data
idx += 1

# ── B2B users (ZigEXn) ──
b2b_names = [
  ['Yamada Keiko', 'learning-admin@zigexn.vn'],
  ['Tanaka Hiroshi', 'hr.tanaka@zigexn.vn'],
  ['Suzuki Akiko', 'training@zigexn.vn'],
  ['Nakamura Sota', 'dev.nakamura@zigexn.vn'],
  ['Watanabe Yui', 'it.watanabe@zigexn.vn'],
  ['Nguyễn Thị Bích', 'nguyen.bich@zigexn.vn'],
  ['Trần Minh Tú', 'tran.tu@zigexn.vn'],
  ['Lê Hoàng Nam', 'le.nam@zigexn.vn'],
  ['Phạm Khánh Linh', 'pham.linh@zigexn.vn'],
  ['Vũ Thanh Tùng', 'vu.tung@zigexn.vn'],
]
b2b_names.each do |name, email|
  user_rows << {
    name: name, email: email,
    encrypted_password: SEED_PWD, role: 'student',
    avatar_url: AVATAR_URLS[idx % AVATAR_URLS.size],
    confirmed_at: ts(300), created_at: ts(300), updated_at: ts(2),
    confirmation_sent_at: ts(300), confirmation_token: SecureRandom.hex(16),
    organization_id: org.id
  }
  idx += 1
end

# ── Specific instructors (50 from SEED_INSTRUCTORS) ──
SEED_INSTRUCTORS.each do |inst|
  user_rows << {
    name: inst[:name], email: inst[:email],
    encrypted_password: SEED_PWD, role: 'instructor',
    avatar_url: AVATAR_URLS[idx % AVATAR_URLS.size],
    confirmed_at: ts(rand(500..800)), created_at: ts(rand(500..800)), updated_at: ts(rand(1..30)),
    confirmation_sent_at: ts(rand(500..800)), confirmation_token: SecureRandom.hex(16),
    organization_id: nil
  }
  idx += 1
end

# ── Generated instructors (150 more, mix VN + international) ──
email_set = Set.new(user_rows.map { |u| u[:email] })

150.times do |i|
  name = case i % 4
         when 0 then random_vn_name
         when 1 then JP_NAMES[i % JP_NAMES.size].join(' ')
         when 2 then KR_NAMES[i % KR_NAMES.size].join(' ')
         else        INTL_NAMES[i % INTL_NAMES.size].join(' ')
         end
  email = uniq_email(name, idx + 1000)
  email = "instructor.#{i}@gmail.com" if email_set.include?(email)
  email_set << email
  day_joined = rand(400..900)
  user_rows << {
    name: name, email: email,
    encrypted_password: SEED_PWD, role: 'instructor',
    avatar_url: AVATAR_URLS[idx % AVATAR_URLS.size],
    confirmed_at: ts(day_joined), created_at: ts(day_joined), updated_at: ts(rand(1..60)),
    confirmation_sent_at: ts(day_joined), confirmation_token: SecureRandom.hex(16),
    organization_id: nil
  }
  idx += 1
end

# ── Students (4,800) ──
STUDENT_ARCHETYPES = [
  :new_learner, :active_learner, :vip_learner, :dropout, :completer
].freeze

4800.times do |i|
  name = case i % 5
         when 0, 1 then random_vn_name
         when 2    then JP_NAMES[i % JP_NAMES.size].join(' ')
         when 3    then KR_NAMES[i % KR_NAMES.size].join(' ')
         else           INTL_NAMES[i % INTL_NAMES.size].join(' ')
         end
  email = uniq_email(name, idx + 2000)
  email = "student.#{i}@gmail.com" if email_set.include?(email)
  email_set << email

  day_joined = case i % STUDENT_ARCHETYPES.size
               when 0 then rand(1..30)       # new
               when 1 then rand(30..180)     # active
               when 2 then rand(200..600)    # vip (long-time)
               when 3 then rand(60..400)     # dropout
               else        rand(100..700)    # completer
               end

  user_rows << {
    name: name, email: email,
    encrypted_password: SEED_PWD, role: 'student',
    avatar_url: AVATAR_URLS[idx % AVATAR_URLS.size],
    confirmed_at: ts(day_joined), created_at: ts(day_joined), updated_at: ts(rand(0..day_joined)),
    confirmation_sent_at: ts(day_joined), confirmation_token: SecureRandom.hex(16),
    organization_id: nil
  }
  idx += 1
end

batch_insert(User, user_rows)
ok(user_rows.size, 'users')

# Fetch all user IDs grouped by role
all_users      = User.select(:id, :name, :role, :email, :created_at).index_by(&:id)
admin_user     = User.find_by(role: 'admin')
instructor_ids = User.where(role: 'instructor').order(:id).pluck(:id)
student_ids    = User.where(role: 'student', organization_id: nil).order(:id).pluck(:id)
b2b_user_ids   = User.where(organization_id: org.id).pluck(:id)

# =============================================================================
# STEP 3: PROFILES
# =============================================================================
step '(3/14) Creating profiles'

GENDERS = %w[male female other prefer_not_to_say].freeze
all_user_ids = User.pluck(:id)

profile_rows = all_user_ids.map.with_index do |uid, i|
  u = all_users[uid]
  {
    user_id: uid,
    bio: i % 3 == 0 ? 'Đam mê học hỏi và phát triển bản thân liên tục.' : nil,
    phone: i % 4 == 0 ? "09#{rand(10_000_000..99_999_999)}" : nil,
    gender: GENDERS[i % GENDERS.size],
    dob: i % 2 == 0 ? Date.new(rand(1985..2002), rand(1..12), rand(1..28)) : nil,
    created_at: u.created_at, updated_at: u.created_at
  }
end

batch_insert(Profile, profile_rows)
ok(profile_rows.size, 'profiles')

# =============================================================================
# STEP 4: WALLETS + SUBSCRIPTIONS
# =============================================================================
step '(4/14) Creating wallets and subscriptions'

wallet_rows = all_user_ids.map.with_index do |uid, i|
  {
    user_id: uid,
    balance: case i % 10
             when 0    then rand(0..50_000_000).to_f / 100.0
             when 1, 2 then rand(0..5_000_000).to_f / 100.0
             else      rand(0..500_000).to_f / 100.0
             end,
    created_at: ts(rand(100..500)), updated_at: ts(rand(0..30))
  }
end

batch_insert(Wallet, wallet_rows)
ok(wallet_rows.size, 'wallets')

# Subscriptions for ~30% of active students
subscription_candidates = student_ids.sample((student_ids.size * 0.30).to_i)
sub_rows = subscription_candidates.map.with_index do |uid, i|
  start_days = rand(10..365)
  {
    user_id: uid,
    plan_type: [0, 1, 2][i % 3],
    status: %w[active active active canceled][i % 4],
    current_period_start: ts(start_days),
    current_period_end: ts(start_days - 30),
    stripe_subscription_id: "sub_#{SecureRandom.hex(12)}",
    stripe_customer_id: "cus_#{SecureRandom.hex(12)}",
    created_at: ts(start_days), updated_at: ts(rand(0..10))
  }
end

batch_insert(Subscription, sub_rows)
ok(sub_rows.size, 'subscriptions')

# =============================================================================
# STEP 5: INSTRUCTOR PROFILES
# =============================================================================
step '(5/14) Creating instructor profiles'

SPECIALTIES = [
  'Machine Learning & AI', 'Web Development', 'Financial Analysis',
  'Digital Marketing', 'DevOps & Cloud', 'UI/UX Design',
  'Data Science', 'Mobile Development', 'English Teaching',
  'Business Strategy', 'Cybersecurity', 'Database Engineering',
  'NLP & LLM', 'Product Management', 'Video Production',
  'Japanese Language', 'Korean Language', 'Graphic Design',
  'Frontend Development', 'Backend Development', 'Robotics & IoT',
].freeze

# Map specific instructors to their bios
specific_bio_map = {}
SEED_INSTRUCTORS.each_with_index do |inst, i|
  u = User.find_by(email: inst[:email])
  next unless u
  specific_bio_map[u.id] = { bio: inst[:bio], specialty: inst[:specialty] }
end

ip_rows = instructor_ids.map.with_index do |uid, i|
  data = specific_bio_map[uid]
  bio = data ? data[:bio] : "Chuyên gia #{SPECIALTIES[i % SPECIALTIES.size]} với nhiều năm kinh nghiệm thực chiến trong ngành."
  {
    user_id: uid,
    bio_detailed: bio,
    linkedin_url: i % 2 == 0 ? "https://linkedin.com/in/#{name_slug(all_users[uid].name)}" : nil,
    cv_url: nil,
    website_url: i % 4 == 0 ? "https://#{name_slug(all_users[uid].name).gsub('.', '-')}.dev" : nil,
    bank_name: %w[Vietcombank Techcombank VPBank BIDV Agribank MBBank][i % 6],
    bank_account_number: "#{rand(1_000_000_000..9_999_999_999)}",
    bank_account_name: all_users[uid].name.upcase,
    status: i < 180 ? 'approved' : (i < 195 ? 'pending' : 'rejected'),
    admin_note: i >= 195 ? 'Hồ sơ không đủ điều kiện' : nil,
    phone: "09#{rand(10_000_000..99_999_999)}",
    created_at: ts(rand(100..700)), updated_at: ts(rand(0..30))
  }
end

batch_insert(InstructorProfile, ip_rows)
ok(ip_rows.size, 'instructor_profiles')

# =============================================================================
# STEP 6: CATEGORIES
# =============================================================================
step '(6/14) Creating categories'

cat_map = {}  # key => id

# Insert main categories first
main_cats = CATEGORY_FLAT.select { |c| c[:parent].nil? }
main_cats.each do |c|
  cat = Category.create!(name: c[:name], description: "Khám phá các khóa học về #{c[:name]}", parent_id: nil)
  cat_map[c[:key]] = cat.id
end

# Insert sub-categories
sub_cats = CATEGORY_FLAT.select { |c| c[:parent] }
sub_cats.each do |c|
  parent_id = cat_map[c[:parent]]
  next unless parent_id
  cat = Category.create!(name: c[:name], description: "Chuyên sâu về #{c[:name]}", parent_id: parent_id)
  cat_map[c[:key]] = cat.id
end

ok(cat_map.size, 'categories')
