# frozen_string_literal: true
# =============================================================================
# db/seeds.rb — EDTECH PLATFORM PRODUCTION SEED DATA
# =============================================================================
# Usage:    bundle exec rails db:seed
# Ruby:     >= 2.7  |  Rails: 7.0  |  DB: MySQL 8.0 (utf8mb4)
# Duration: ~25–45 minutes for full dataset
#
# Scale:
#   Users:       5,011  (1 admin · 10 B2B · 200 instructors · 4,800 students)
#   Categories:  22 main + ~110 sub
#   Courses:     510+
#   Modules:     ~3,500  |  Lessons: ~22,000
#   Quizzes:     ~1,500  |  Questions: ~18,000
#   Enrollments: ~65,000
#   Reviews:     ~12,000
#   Comments:    ~55,000
# =============================================================================

require 'securerandom'
require 'bcrypt'
require 'set'

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
SEED_START = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def elapsed
  (Process.clock_gettime(Process::CLOCK_MONOTONIC) - SEED_START).round(1)
end

def step(title)
  puts "\n  [#{elapsed.to_s.rjust(7)}s]  ── #{title}"
  $stdout.flush
end

def ok(count, unit = 'records')
  puts "           ✓  #{count.to_s.rjust(8)} #{unit} created"
  $stdout.flush
end

# Single BCrypt hash for all seed users (cost=4 is fast for dev seeds)
SEED_PWD  = BCrypt::Password.create('Demo@12345!', cost: 4).to_s.freeze
SEED_NOW  = Time.current.freeze

def ts(offset_days = 0, offset_hours = 0)
  (SEED_NOW - offset_days.days - offset_hours.hours).strftime('%Y-%m-%d %H:%M:%S')
end

def rand_ts(from_days_ago, to_days_ago = 0)
  ts(rand(from_days_ago..to_days_ago))
end

# Safely slugify a Vietnamese/Japanese/Korean name for email
def name_slug(name)
  name
    .unicode_normalize(:nfd)
    .encode('ASCII', invalid: :replace, undef: :replace, replace: '')
    .downcase
    .gsub(/[^a-z0-9\s\-]/, '')
    .strip
    .gsub(/\s+/, '.')
end

def uniq_email(name, idx, domain = nil)
  slug  = name_slug(name)
  slug  = "user#{idx}" if slug.empty?
  dom   = domain || %w[gmail.com yahoo.com outlook.com hotmail.com icloud.com][idx % 5]
  suffix = idx % 4 == 0 ? (idx % 97 + 1).to_s : ''
  "#{slug}#{suffix}@#{dom}"
end

def batch_insert(model, rows, batch_size: 500)
  rows.each_slice(batch_size) { |batch| model.insert_all(batch) }
end

# ─────────────────────────────────────────────────────────────────────────────
# DATA CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

VN_HO = %w[
  Nguyễn Trần Lê Phạm Hoàng Huỳnh Phan Vũ Võ Đặng
  Bùi Đỗ Hồ Ngô Dương Lý Đinh Hà Lưu Tô
  Phùng Mạc Kiều Ninh Vương Tống Tạ Dư Hứa Bạch
].freeze

VN_DEM = %w[
  Văn Thị Hoàng Hữu Minh Đức Quang Thành Ngọc Thanh
  Bảo Xuân Hồng Gia Tố Kim Khánh Mỹ Phú Tiến
  Công Trí Tấn Nhật Anh Tâm Khoa Tuấn Long
].freeze

VN_TEN = %w[
  An Anh Bình Chi Dũng Giang Hà Hải Hạnh Hiếu
  Hòa Hương Khoa Lan Linh Long Mai Minh Nam Nga
  Ngọc Nhung Phong Phương Quân Quỳnh Sơn Tâm Thanh Thảo
  Thu Thủy Tiến Trung Tuấn Tùng Uyên Việt Xuân Yến
  Duy Khải Khang Khánh Kiên Lâm Lộc Nhân Phúc Tài
  Đạt Đức Hào Hưng Khải Kỳ Lực Nghĩa Phát Thịnh
].freeze

JP_NAMES = [
  ['Kenji', 'Tanaka'], ['Yuki', 'Suzuki'], ['Hiroshi', 'Sato'],
  ['Akiko', 'Watanabe'], ['Naomi', 'Yamamoto'], ['Takashi', 'Nakamura'],
  ['Yoshiko', 'Kobayashi'], ['Makoto', 'Kato'], ['Haruto', 'Ito'],
  ['Mio', 'Yoshida'], ['Sota', 'Kimura'], ['Rin', 'Hayashi'],
  ['Hana', 'Inoue'], ['Daiki', 'Sasaki'], ['Yui', 'Matsumoto'],
  ['Ryu', 'Fujiwara'], ['Aoi', 'Ogawa'], ['Kei', 'Nishimura'],
  ['Emi', 'Tanimoto'], ['Jun', 'Moriwaki'],
].freeze

KR_NAMES = [
  ['Jisoo', 'Kim'], ['Minho', 'Park'], ['Sooyoung', 'Lee'],
  ['Taehyung', 'Choi'], ['Jennie', 'Jung'], ['Sehun', 'Kang'],
  ['Yeri', 'Cho'], ['Hyunwoo', 'Yoon'], ['Jiyeon', 'Jang'],
  ['Seojun', 'Lim'], ['Minjae', 'Han'], ['Hayeon', 'Oh'],
  ['Donghyun', 'Shin'], ['Soyeon', 'Kwon'],
].freeze

INTL_NAMES = [
  ['David', 'Chen'], ['Sarah', 'Johnson'], ['Michael', 'Brown'],
  ['Emma', 'Wilson'], ['James', 'Anderson'], ['Olivia', 'Taylor'],
  ['Lucas', 'Martinez'], ['Sophie', 'Garcia'], ['Alex', 'Thompson'],
  ['Jessica', 'White'], ['Daniel', 'Harris'], ['Megan', 'Clark'],
  ['Ryan', 'Lewis'], ['Amanda', 'Robinson'], ['Kevin', 'Walker'],
  ['Nicole', 'Hall'], ['Thomas', 'Young'], ['Ashley', 'King'],
  ['Jason', 'Scott'], ['Lauren', 'Adams'],
].freeze

def random_vn_name
  "#{VN_HO.sample} #{VN_DEM.sample} #{VN_TEN.sample}"
end

# ── SPECIFIC INSTRUCTOR DATA (first 50, then generated) ───────────────────────
SEED_INSTRUCTORS = [
  { name: 'Nguyễn Thành Vinh',    email: 'nguyen.thanh.vinh@gmail.com',    bio: 'Senior ML Engineer tại Google Việt Nam, 8 năm kinh nghiệm nghiên cứu Machine Learning và Computer Vision. Tác giả 3 bài báo khoa học tại NeurIPS và ICML.',                     specialty: 'Machine Learning' },
  { name: 'Trần Minh Hiếu',       email: 'tran.minh.hieu@gmail.com',       bio: 'Full-Stack Developer với 10 năm kinh nghiệm, chuyên React/Node.js. Từng làm việc tại Shopee và MoMo. Mentor hơn 500 lập trình viên.',                                            specialty: 'Web Development' },
  { name: 'Lê Hoàng Giang',       email: 'le.hoang.giang@outlook.com',     bio: 'CFA Charterholder, 12 năm kinh nghiệm Phân tích Tài chính tại Dragon Capital và VinaCapital. Chuyên gia định giá cổ phiếu và quản lý danh mục.',                                specialty: 'Financial Analysis' },
  { name: 'Phạm Ngọc Lan',        email: 'pham.ngoc.lan@gmail.com',        bio: 'Head of Marketing tại Tiki, 9 năm kinh nghiệm Digital Marketing. Chuyên về Performance Marketing, SEO/SEM và Growth Hacking.',                                                     specialty: 'Digital Marketing' },
  { name: 'Vũ Đức Minh',          email: 'vu.duc.minh@gmail.com',          bio: 'DevOps Engineer tại VNG Cloud, chứng chỉ AWS Solutions Architect Professional và CKA. 7 năm xây dựng hạ tầng cho hệ thống triệu users.',                                           specialty: 'DevOps & Cloud' },
  { name: 'Đặng Thị Thu Hương',   email: 'dang.thu.huong@gmail.com',       bio: 'Senior UX Designer tại Grab, Figma Champion. 8 năm thiết kế sản phẩm digital cho thị trường Đông Nam Á. Speaker tại UX Conf Vietnam 2023.',                                       specialty: 'UI/UX Design' },
  { name: 'Bùi Quang Nam',        email: 'bui.quang.nam@gmail.com',        bio: 'Data Scientist tại VinAI Research, PhD toán học ứng dụng ĐH Bách khoa Hà Nội. Chuyên gia Time Series và Anomaly Detection.',                                                      specialty: 'Data Science' },
  { name: 'Hồ Minh Tuấn',         email: 'ho.minh.tuan@yahoo.com',         bio: 'Mobile Developer 7 năm, Flutter GDE (Google Developer Expert). Xây dựng app 1M+ downloads. Tech Lead tại KMS Technology.',                                                         specialty: 'Mobile Development' },
  { name: 'Ngô Thanh Phương',     email: 'ngo.thanh.phuong@gmail.com',     bio: 'IELTS 8.5, từng là giáo viên tại IDP và British Council. Chuyên luyện thi IELTS và Business English cho người đi làm.',                                                            specialty: 'English Teaching' },
  { name: 'Dương Hoàng Long',     email: 'duong.hoang.long@gmail.com',     bio: 'MBA Harvard, 15 năm kinh nghiệm chiến lược doanh nghiệp. Cựu Director tại McKinsey Vietnam. Mentor startup, investor angel.',                                                       specialty: 'Business Strategy' },
  { name: 'Lý Xuân Trường',       email: 'ly.xuan.truong@gmail.com',       bio: 'Robotics Engineer tại VinAI, Tiến sĩ Cơ điện tử ĐH Bách khoa TP.HCM. Chuyên gia ROS2, SLAM và Computer Vision cho robot tự hành.',                                               specialty: 'Robotics & IoT' },
  { name: 'Huỳnh Văn Phước',      email: 'huynh.van.phuoc@gmail.com',      bio: 'Videographer & Filmmaker 10 năm. Adobe Certified Expert Premiere Pro. Đã sản xuất hơn 200 dự án video thương mại cho các nhãn hàng lớn.',                                          specialty: 'Video Production' },
  { name: 'Phan Thị Mỹ Linh',     email: 'phan.my.linh@gmail.com',         bio: 'Senior Product Manager tại Zalo, 6 năm quản lý sản phẩm. Scrum Master certified. Chuyên về Product Discovery và 0-to-1 product.',                                                  specialty: 'Product Management' },
  { name: 'Đinh Công Khánh',      email: 'dinh.cong.khanh@outlook.com',    bio: 'Backend Engineer tại Base.vn, 8 năm kinh nghiệm Go và Rust. Chuyên kiến trúc microservices, event sourcing và distributed systems.',                                               specialty: 'Backend Development' },
  { name: 'Tô Thị Hồng Nhung',    email: 'to.hong.nhung@gmail.com',        bio: 'Graphic Designer 9 năm tại Leo Burnett và Ogilvy Vietnam. Chuyên Brand Identity, Packaging Design và Art Direction.',                                                              specialty: 'Graphic Design' },
  { name: 'Hà Minh Đức',          email: 'ha.minh.duc@gmail.com',          bio: 'Cybersecurity Expert, OSCP và CEH certified. 8 năm Penetration Testing cho ngân hàng và fintech. Speaker BlackHat Asia 2022.',                                                      specialty: 'Cybersecurity' },
  { name: 'Ninh Thị Phương Thảo', email: 'ninh.phuong.thao@gmail.com',     bio: 'Content Creator & SEO Specialist, 7 năm. Chuyên Content Marketing, xây dựng thương hiệu cá nhân và Social Media Strategy.',                                                       specialty: 'Content Marketing' },
  { name: 'Mạc Văn Kiên',         email: 'mac.van.kien@gmail.com',         bio: 'AI Research Engineer tại FPT AI Center. PhD NLP. Chuyên Large Language Models, Text Mining và Conversational AI.',                                                                 specialty: 'NLP & LLM' },
  { name: 'Tống Thị Bảo Châu',    email: 'tong.bao.chau@gmail.com',        bio: 'Kế toán trưởng 12 năm, ACCA. Chuyên tư vấn thuế doanh nghiệp và lập báo cáo tài chính cho SME. Cộng tác viên Ernst & Young.',                                                     specialty: 'Accounting & Tax' },
  { name: 'Nguyễn Quốc Thịnh',    email: 'nguyen.quoc.thinh@gmail.com',    bio: 'Senior Data Engineer tại Lazada, 7 năm xây dựng data pipeline với Spark, Airflow và dbt. Chuyên Real-time streaming với Kafka.',                                                   specialty: 'Data Engineering' },
  { name: 'Kenji Tanaka',          email: 'kenji.tanaka@gmail.com',         bio: 'Japanese Language Instructor, JLPT N1. 10 năm giảng dạy tiếng Nhật tại Nhật Bản và Việt Nam. Chuyên luyện thi JLPT N2/N3 cho người đi làm.',                                       specialty: 'Japanese Language' },
  { name: 'Yuki Suzuki',           email: 'yuki.suzuki@gmail.com',          bio: 'Business Japanese Specialist. Cựu nhân viên Sumitomo, 8 năm kinh nghiệm làm việc trong môi trường doanh nghiệp Nhật. Chuyên Keigo và văn phong công sở.',                           specialty: 'Business Japanese' },
  { name: 'Jisoo Kim',             email: 'jisoo.kim@gmail.com',            bio: 'Korean Language Tutor, TOPIK 6. Giảng viên tiếng Hàn tại Đại học Ngoại ngữ Hà Nội. Chuyên luyện thi TOPIK và giao tiếp hàng ngày.',                                               specialty: 'Korean Language' },
  { name: 'David Chen',            email: 'david.chen@gmail.com',           bio: 'Senior Software Engineer tại Meta, Stanford CS alumnus. 12 năm kinh nghiệm React, TypeScript và System Design. OSS contributor.',                                                   specialty: 'Frontend Development' },
  { name: 'Sarah Johnson',         email: 'sarah.johnson@outlook.com',      bio: 'UX Research Lead at Airbnb, 9 years. Expert in Mixed-Methods Research, Usability Testing and Quantitative UX. Author of "Designing for Trust".',                                    specialty: 'UX Research' },
  { name: 'Michael Brown',         email: 'michael.brown@gmail.com',        bio: 'Blockchain Architect and Web3 developer, 7 years. Solidity, Rust for Solana. Founded 2 DeFi projects. Tech advisor for crypto startups.',                                           specialty: 'Blockchain & Web3' },
  { name: 'Emma Wilson',           email: 'emma.wilson@gmail.com',          bio: 'CFA, Portfolio Manager at JP Morgan for 11 years. Expert in Equity Analysis, Financial Modeling and Alternative Investments.',                                                       specialty: 'Investment & Finance' },
  { name: 'Lucas Martinez',        email: 'lucas.martinez@gmail.com',       bio: 'AWS Ambassador and Solutions Architect, 8 years cloud experience. Built cloud infra for unicorn startups. Speaker at AWS re:Invent.',                                               specialty: 'AWS & Cloud' },
  { name: 'Sophie Garcia',         email: 'sophie.garcia@gmail.com',        bio: 'IELTS Examiner and English Coach for 10 years. Specialized in Academic Writing, Speaking for Professionals and Business Communication.',                                             specialty: 'IELTS & English' },
  { name: 'Minho Park',            email: 'minho.park@gmail.com',           bio: 'Korean Business Language Expert and HR Consultant at LG Electronics Vietnam. Specializes in Korean workplace culture and business etiquette.',                                       specialty: 'Korean Business' },
  { name: 'Phạm Hữu Lộc',         email: 'pham.huu.loc@gmail.com',         bio: 'Senior iOS Developer, 8 năm. Apple Developer Academy mentor. Chuyên Swift, SwiftUI và Core ML cho iOS apps 5-star trên App Store.',                                                specialty: 'iOS Development' },
  { name: 'Đỗ Thị Kim Anh',       email: 'do.kim.anh@gmail.com',           bio: 'Power BI & Tableau Specialist, 6 năm BI Consulting cho Fortune 500. Chuyên DAX, data modeling và enterprise dashboard.',                                                           specialty: 'Business Intelligence' },
  { name: 'Ngô Gia Bảo',          email: 'ngo.gia.bao@gmail.com',          bio: 'Quản lý đầu tư 14 năm, cựu Giám đốc SSI Asset Management. CFA Level 3. Chuyên phân tích kỹ thuật và chiến lược trading chứng khoán.',                                             specialty: 'Stock Market' },
  { name: 'Trần Thị Lan Chi',      email: 'tran.lan.chi@gmail.com',         bio: 'UX/UI Lead tại Sendo, 7 năm thiết kế sản phẩm e-commerce. Figma Instructor, Design Thinking Facilitator. Mentored 300+ designers.',                                               specialty: 'Product Design' },
  { name: 'Vương Minh Khoa',       email: 'vuong.minh.khoa@gmail.com',      bio: 'Kubernetes & Cloud Native Expert. CNCF Ambassador. 9 năm xây dựng platform engineering cho các công ty FinTech lớn.',                                                              specialty: 'Kubernetes & Platform Eng' },
  { name: 'Lưu Thị Khánh Vân',    email: 'luu.khanh.van@gmail.com',        bio: 'Giáo viên tiếng Anh IELTS 9.0. Cambridge CELTA certified. 12 năm kinh nghiệm dạy Pronunciation và Academic Writing.',                                                              specialty: 'English Pronunciation' },
  { name: 'Phùng Đức Hào',        email: 'phung.duc.hao@gmail.com',        bio: 'Django & Python Expert. 9 năm backend development. Đã xây dựng hệ thống cho 10M+ người dùng. Chuyên DRF, Celery và PostgreSQL optimization.',                                      specialty: 'Python Backend' },
  { name: 'Bạch Thị Thanh Hà',    email: 'bach.thanh.ha@gmail.com',        bio: 'Adobe Creative Suite Expert (Photoshop, Illustrator, InDesign). 10 năm thiết kế đồ họa cho báo chí và quảng cáo.',                                                               specialty: 'Graphic Design' },
  { name: 'Tạ Quang Vinh',         email: 'ta.quang.vinh@gmail.com',        bio: 'Startup Founder & Lean Product Expert. Gây quỹ 2M USD. 10 năm kinh nghiệm xây dựng product từ 0 đến PMF.',                                                                        specialty: 'Lean Startup & Product' },
  { name: 'Hứa Thị Ngọc Hà',      email: 'hua.ngoc.ha@gmail.com',          bio: 'Chuyên gia quản lý tài chính cá nhân và coaching tài chính. Certified Financial Planner (CFP). Tác giả cuốn "Tiền và Tự Do".',                                                    specialty: 'Personal Finance' },
  { name: 'Dư Minh Tâm',          email: 'du.minh.tam@gmail.com',          bio: 'Laravel & Vue.js Expert. 8 năm xây dựng SaaS products. Laravel Core Contributor. Speaker tại Laracon SEA.',                                                                        specialty: 'Laravel & Vue.js' },
  { name: 'Kiều Thị Thu Trang',    email: 'kieu.thu.trang@gmail.com',       bio: 'Marketing Manager tại Vinamilk, MBA ĐH RMIT. Chuyên Brand Management, Integrated Marketing Campaign và Consumer Insights.',                                                        specialty: 'Brand Marketing' },
  { name: 'Alex Thompson',         email: 'alex.thompson@gmail.com',        bio: 'Data Engineer at Spotify, ex-Netflix. Specializes in large-scale data pipelines with Apache Spark, Kafka and dbt. Open source contributor.',                                        specialty: 'Data Engineering' },
  { name: 'Jessica White',         email: 'jessica.white@outlook.com',      bio: 'Certified Scrum Master and Agile Coach, PMP. 10 years leading distributed product teams at Microsoft and Atlassian.',                                                               specialty: 'Agile & Project Mgmt' },
  { name: 'Vũ Thị Thanh Ngân',    email: 'vu.thanh.ngan@gmail.com',        bio: 'Chuyên gia phân tích Kỹ thuật, 10 năm trading chứng khoán và forex. Giảng viên tại FTMO Vietnam. Chuyên Price Action và hệ thống giao dịch tự động.',                             specialty: 'Technical Analysis' },
  { name: 'Hoàng Xuân Phát',      email: 'hoang.xuan.phat@gmail.com',      bio: 'Android Developer 7 năm. Kotlin Coroutines & Jetpack Compose Expert. Xây dựng app banking cho TPBank và Techcombank.',                                                             specialty: 'Android Development' },
  { name: 'Nguyễn Thị Hồng Hạnh', email: 'nguyen.hong.hanh@gmail.com',     bio: 'Chuyên gia Dinh dưỡng và Sức khỏe, thạc sĩ ĐH Y Dược. Blogger sức khỏe 500K followers. Chuyên tư vấn chế độ ăn và luyện tập.',                                                  specialty: 'Health & Nutrition' },
  { name: 'Phạm Văn Đạt',         email: 'pham.van.dat@gmail.com',         bio: 'Next.js & Vercel Expert. 6 năm frontend development, chuyên React Server Components, Edge Functions và performance optimization.',                                                  specialty: 'Next.js & React' },
  { name: 'Trần Công Nghĩa',       email: 'tran.cong.nghia@gmail.com',      bio: 'Senior DBA MySQL & PostgreSQL, 10 năm. Chuyên database sharding, replication và performance tuning cho hệ thống hàng triệu QPS.',                                                  specialty: 'Database Engineering' },
  { name: 'Lê Thị Bảo Trân',      email: 'le.bao.tran@gmail.com',          bio: 'Motion Designer & After Effects Expert. 8 năm tạo visual identity và animation cho thương hiệu. Adobe MAX Speaker 2022.',                                                          specialty: 'Motion Design' },
].freeze

# ── REVIEW TEXT POOLS ─────────────────────────────────────────────────────────
REVIEWS_5_STARS = [
  'Khóa học xuất sắc! Instructor giải thích rất rõ ràng, từ lý thuyết đến thực hành đều được trình bày logic. Tôi đã áp dụng ngay vào dự án thực tế sau 2 tuần học.',
  'Đây là khóa học tốt nhất tôi từng tham gia trên bất kỳ nền tảng nào. Nội dung được cập nhật liên tục, bài tập thực hành rất sát với công việc thực tế.',
  'Instructor không chỉ dạy kỹ thuật mà còn chia sẻ kinh nghiệm thực chiến rất giá trị. Phần Q&A được trả lời nhanh và chi tiết.',
  'Sau khi hoàn thành khóa học này, tôi đã được nhận vào vị trí mà mình hằng mơ ước. Kiến thức nền vững và bài tập cuối khóa là điểm mạnh nhất.',
  'Tuyệt vời! Cách trình bày của instructor rất cuốn hút, không hề khô khan. Học mà cảm giác như đang nghe kể chuyện công nghệ.',
  'Dự án capstone ở cuối khóa rất thực tế và có giá trị để đưa vào portfolio. Tôi đã có 3 cuộc phỏng vấn nhờ project này.',
  'Nội dung phong phú, cập nhật theo xu hướng mới nhất năm 2024. Instructor rõ ràng dành nhiều công sức cho từng bài học.',
  'Khóa học có cấu trúc rất tốt, từ dễ đến khó một cách tự nhiên. Phù hợp cho cả người mới bắt đầu lẫn những ai muốn củng cố kiến thức.',
  'Tôi đã thử nhiều khóa học khác nhau nhưng đây là lần đầu tôi hoàn thành 100% mà không bỏ giữa chừng. Chất lượng xứng đáng 5 sao.',
  'Community của khóa học rất sôi động và hỗ trợ nhau tốt. Instructor thường xuyên online và trả lời câu hỏi.',
  'Video chất lượng cao, âm thanh rõ ràng, code được giải thích từng dòng một. Đây là chuẩn mực của khóa học online.',
  'Khóa học thay đổi cách tôi nhìn nhận về lĩnh vực này. Không chỉ học kỹ năng mà còn học cách tư duy như một chuyên gia.',
  'Best investment I have made this year. The practical examples and real-world projects are incredibly valuable.',
  'Instructor has a rare gift for explaining complex topics simply. I went from zero to confident in just 6 weeks.',
  'The level of detail and care put into this course is remarkable. Every question gets answered, usually within hours.',
].freeze

REVIEWS_4_STARS = [
  'Nội dung rất tốt và instructor có kiến thức sâu. Chỉ trừ một điểm là một vài phần video hơi dài, có thể cắt gọn hơn.',
  'Khóa học chất lượng cao, tôi học được nhiều thứ mới. Nếu có thêm bài tập thực hành ở mỗi section thì sẽ hoàn hảo hơn.',
  'Giảng viên rất kiên nhẫn và dễ hiểu. Tốc độ giảng vừa phải. Mong có thêm phần nâng cao trong tương lai.',
  'Kiến thức thực tế và được cập nhật tốt. Phần quiz giúp củng cố kiến thức hiệu quả. Trừ 1 sao vì subtitle tiếng Việt chưa đầy đủ.',
  'Đây là lần đầu tôi học online mà cảm thấy không thua kém học trực tiếp. Tuy nhiên phần cuối khóa hơi vội.',
  'Rất đáng tiền. Instructor chia sẻ nhiều kinh nghiệm thực tế mà sách vở không có. Mong có thêm case study.',
  'Good course overall. The instructor clearly knows the subject well. Some sections could use more examples.',
  'Very informative. I appreciated the depth of coverage. The community forum is helpful but could be more active.',
  'Nội dung phong phú, học được nhiều. Chỉ mong phần hỗ trợ kỹ thuật nhanh hơn một chút.',
  'Khóa học có cấu trúc rõ ràng, dễ theo dõi. Phần final project hơi đơn giản so với mức độ của khóa học.',
].freeze

REVIEWS_3_STARS = [
  'Nội dung tạm được, phù hợp cho người mới bắt đầu. Nhưng người đã có kinh nghiệm sẽ thấy hơi cơ bản.',
  'Tốc độ giảng hơi nhanh ở một số phần, phải xem lại nhiều lần. Nội dung ổn nhưng cần được cập nhật thêm.',
  'Khóa học cung cấp kiến thức nền tốt nhưng thiếu chiều sâu. Cần thêm nhiều ví dụ thực tế hơn.',
  'Instructor có kiến thức tốt nhưng cách trình bày đôi khi hơi khó theo. Phần quiz hơi dễ.',
  'Average course. Gets the job done but nothing exceptional. Some topics feel rushed.',
].freeze

REVIEWS_2_STARS = [
  'Kiến thức ổn nhưng chất lượng video không tốt, tiếng ồn nhiều. Cần cải thiện chất lượng sản xuất.',
  'Nội dung bị outdated, nhiều phần không còn phù hợp với phiên bản hiện tại. Mong instructor cập nhật sớm.',
  'Thất vọng. Phần mô tả khóa học hứa hẹn nhiều hơn những gì thực sự dạy. Cảm giác bị mislead.',
  'Instructor giảng quá nhanh và không có đủ ví dụ thực tế. Hỏi câu hỏi không được trả lời.',
].freeze

REVIEWS_1_STAR = [
  'Khóa học quảng cáo không đúng với nội dung thực tế. Rất thất vọng với chất lượng.',
  'Instructor không trả lời câu hỏi trong suốt 2 tuần. Không xứng đáng với số tiền bỏ ra.',
  'Content is completely outdated. Half the code doesn\'t work anymore. Waste of money.',
].freeze

# ── COMMENT POOLS ────────────────────────────────────────────────────────────
LEARNER_COMMENTS = [
  'Cảm ơn instructor! Phần này giải thích rõ hơn tài liệu tôi đọc trước đó rất nhiều.',
  'Tôi bị kẹt ở bước cài đặt môi trường, ai có thể giúp không? Lỗi báo "module not found".',
  'Bài học này rất hay! Tôi đã áp dụng ngay vào project cá nhân và thấy hiệu quả rõ rệt.',
  'Xin hỏi instructor: nếu dùng phiên bản mới hơn thì có cần điều chỉnh gì không ạ?',
  'Phần này tôi xem đi xem lại 3 lần mới hiểu hết. Concept khó nhưng được giải thích tốt.',
  'Tôi làm theo đúng hướng dẫn nhưng bị lỗi ở bước cuối. Đã gửi code lên forum, mọi người xem giúp.',
  'Khá thú vị khi thấy ứng dụng thực tế của lý thuyết này. Trước đây tôi không hiểu tại sao phải học.',
  'Ai có thể giải thích thêm về phần so sánh hai approach ở phút 18:30 không? Tôi chưa rõ trade-off.',
  'Đã hoàn thành bài tập! Kết quả của tôi khớp với ví dụ trong video. Vui quá!',
  'Instructor ơi, bài tiếp theo có thể nói thêm về cách optimize không ạ? Tôi thấy solution hiện tại hơi chậm.',
  'Phần lý thuyết hơi khô, nhưng khi vào practice thì rất thú vị. Cân bằng tốt!',
  'Tôi có background khác nhưng vẫn theo được bài giảng này. Instructor giải thích rất accessible.',
  'Câu hỏi: cách tiếp cận này có còn được dùng trong industry không hay đã có phương pháp tốt hơn?',
  'Bài học ngắn gọn nhưng đủ ý, không bị drag. Chính xác là những gì tôi cần.',
  'Tôi đã share bài học này với team, ai cũng thấy valuable. Cảm ơn rất nhiều!',
  'Phần demo thực chiến này hay hơn nhiều tutorial trên YouTube tôi từng xem.',
  'Có ai biết cách fix lỗi này không: "TypeError: cannot unpack non-sequence None"? Đã Google nhưng chưa ra.',
  'Instructor reply câu hỏi rất nhanh, cảm giác như học trực tiếp. Đây là điểm cộng lớn nhất.',
  'Bài này nên được đặt trước bài hôm qua vì nó là prerequisite. Nhưng vẫn hiểu được sau khi học xong.',
  'Xong rồi! Mất 3 ngày mới debug xong bug ở phần này nhưng học được rất nhiều từ quá trình đó.',
  'Mình đang học song song với docs chính thức. Cách instructor giải thích dễ hiểu hơn tài liệu gốc nhiều.',
  'Hỏi thật: kiến thức trong bài này có đủ để đi phỏng vấn công ty lớn không ạ?',
  'Great explanation! I was struggling with this concept for weeks before this video clicked.',
  'Can anyone share their solution to the exercise? I want to compare approaches.',
  'The pace is perfect. Not too fast, not too slow. Instructor clearly practiced the delivery.',
  'This answered a question I\'ve had for months. The analogy used makes it so intuitive.',
  'Just finished the assignment. Really challenging but worth the effort.',
  'Is there any recommended reading alongside this course? Want to go deeper.',
  'Có chỗ nào tôi có thể download slide bài giảng không ạ? Muốn in ra để học offline.',
  'Phần code demo chạy ngon trên máy tôi. Cảm ơn instructor đã chuẩn bị kỹ file setup.',
  'Bài test cuối section này khó hơn tôi nghĩ. Phải xem lại video trước khi làm đúng.',
  'Instructor thấy tôi hỏi câu ngớ ngẩn không ạ? 😅 Mới học nên còn nhiều chỗ chưa hiểu.',
  'Mình đã pass quiz sau 2 lần thử. Lần đầu sai 3 câu nhưng hiểu rõ lý do rồi. Học hỏi được nhiều!',
].freeze

INSTRUCTOR_REPLIES = [
  'Câu hỏi hay! Đây là điểm nhiều học viên thường nhầm lẫn. Hãy chú ý đến...',
  'Cảm ơn bạn đã chia sẻ! Đúng là cách đó cũng hoạt động được, nhưng approach trong bài có ưu điểm hơn ở chỗ...',
  'Lỗi bạn gặp thường xảy ra khi version không khớp. Hãy thử chạy lệnh sau...',
  'Great question! This is actually a common misconception. The key difference is...',
  'Bạn đã làm đúng rồi! Kết quả đó là bình thường. Tiếp tục nhé.',
  'Tôi sẽ thêm phần này vào bài học tiếp theo theo phản hồi của bạn. Cảm ơn!',
  'Vấn đề bạn đề cập rất hay. Trong industry, người ta thường dùng cách thứ hai vì...',
  'Slide sẽ được upload lên Resources section trong vài ngày nữa nhé.',
  'Đây là link đến tài liệu tham khảo thêm mà bạn hỏi...',
  'Bạn đúng hoàn toàn, cảm ơn đã chỉ ra! Tôi sẽ thêm note vào video.',
].freeze

puts "\n  [#{elapsed}s]  ── Data constants loaded"
$stdout.flush
