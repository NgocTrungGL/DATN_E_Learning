# frozen_string_literal: true
# db/seeds/00_helpers.rb

module SeedHelpers
  # ── Runtime globals ──────────────────────────────────────
  NOW            = Time.current
  TODAY          = Date.current
  THREE_YRS_AGO  = 3.years.ago
  ONE_YR_AGO     = 1.year.ago

  SEED_PASSWORD  = BCrypt::Password.create('Education@2024!', cost: BCrypt::Engine::MIN_COST)

  # ── Name data ────────────────────────────────────────────
  VN_LAST = %w[
    Nguyễn Trần Lê Phạm Hoàng Huỳnh Phan Vũ Đặng Bùi
    Đỗ Hồ Ngô Dương Lý Lưu Trịnh Đinh Tô Phùng
    Cao Tống Bạch Kiều Liêu Lương Hà Vương Mạc Trương
  ].freeze

  VN_MALE_FIRST = %w[
    Minh Hùng Đức Tuấn Quang Nam Huy Khoa Long Phúc
    Dũng Tài Khôi Nhân Thiện Trọng Nhật Bình Cường
    Hưng Thắng Lâm Hoàng Sơn Đạt Phong Thành Kiên Vĩnh
  ].freeze

  VN_FEMALE_FIRST = %w[
    Thảo Linh Mai Hoa Lan Thu Hương Phương Ngọc Trang
    Hằng Yến Nhi Thư Quyên Vy Châu Giang Thanh Xuân
    Diễm Nhung Nhàn Trâm Thùy Diệu Bảo Lệ Tú Kim
  ].freeze

  VN_MALE_MID   = %w[Văn Hữu Quốc Đình Ngọc Trung Minh Thiên Bảo Nhật Tiến Gia Đức Hải].freeze
  VN_FEMALE_MID = %w[Thị Ngọc Hoài Kiều Bích Diệu Mỹ Thanh Phương Lan Kim Tú Lệ Như].freeze

  JP_LAST  = %w[Tanaka Suzuki Sato Watanabe Ito Yamamoto Nakamura Kobayashi Kato Yoshida
                Yamada Sasaki Matsumoto Inoue Kimura Hayashi Shimizu Yamazaki Mori Abe
                Ikeda Hashimoto Yamashita Ishikawa Ogawa Okamoto Nishimura Fujita Goto].freeze

  JP_MALE_FIRST   = %w[Kenji Hiroshi Takashi Yuto Sota Haruto Ren Riku Shota Daiki
                        Kento Ryota Naoki Kazuki Taro Jiro Makoto Tetsuya Noboru Yasushi].freeze
  JP_FEMALE_FIRST = %w[Yuki Akiko Yuna Hina Mio Rin Aoi Nana Sakura Miyu
                        Haruka Ayaka Koharu Kana Misaki Hanako Keiko Reiko Fumiko Tomoko].freeze

  EN_FIRST = %w[James Emma Oliver Sophia William Isabella Noah Mia Liam Charlotte
                Benjamin Amelia Elijah Harper Lucas Mason Evelyn Logan Abigail Alexander
                Emily Daniel Avery Michael Sofia Jackson Scarlett Sebastian Aria Aiden
                Luna Matthew Chloe Ethan Penelope Henry Layla David Hannah Ryan Zoe
                Andrew Natalie Tyler Lily Nathan Victoria Dylan Grace Brandon Alexis].freeze

  EN_LAST  = %w[Smith Johnson Williams Brown Jones Garcia Miller Davis Wilson Moore
                Taylor Anderson Jackson White Harris Martin Thompson Robinson Clark Lewis
                Walker Hall Allen Young Hernandez King Wright Scott Green Baker Adams
                Nelson Carter Mitchell Perez Roberts Turner Phillips Campbell Parker Evans].freeze

  KR_LAST  = %w[Kim Park Lee Choi Jung Kang Cho Yoon Jang Lim Han Oh Seo Kwon Shin Ryu].freeze
  KR_FIRST = %w[MinJun Sujin Jiyeon Hyunwoo Sumin Jiwon Minho Yuna Seojun Chaeyeon
                Jihoon Sooyeon Taehyun Minji Donghyun Nayeon Jungwoo Dahyun Minjae Seoyeon].freeze

  # ── Romanisation map (VN → ASCII) ────────────────────────
  ROMANIZE = {
    'Nguyễn'=>'nguyen','Trần'=>'tran','Lê'=>'le','Phạm'=>'pham',
    'Hoàng'=>'hoang','Huỳnh'=>'huynh','Phan'=>'phan','Vũ'=>'vu',
    'Đặng'=>'dang','Bùi'=>'bui','Đỗ'=>'do','Hồ'=>'ho',
    'Ngô'=>'ngo','Dương'=>'duong','Lý'=>'ly','Lưu'=>'luu',
    'Trịnh'=>'trinh','Đinh'=>'dinh','Tô'=>'to','Phùng'=>'phung',
    'Cao'=>'cao','Tống'=>'tong','Bạch'=>'bach','Kiều'=>'kieu',
    'Lương'=>'luong','Hà'=>'ha','Vương'=>'vuong','Trương'=>'truong',
    'Văn'=>'van','Hữu'=>'huu','Quốc'=>'quoc','Đình'=>'dinh2',
    'Ngọc'=>'ngoc','Trung'=>'trung','Minh'=>'minh','Hoài'=>'hoai',
    'Thiên'=>'thien','Bảo'=>'bao','Nhật'=>'nhat','Tiến'=>'tien',
    'Gia'=>'gia','Đức'=>'duc','Hải'=>'hai','Thị'=>'thi',
    'Thảo'=>'thao','Linh'=>'linh','Mai'=>'mai','Hoa'=>'hoa',
    'Lan'=>'lan','Thu'=>'thu','Hương'=>'huong','Phương'=>'phuong',
    'Trang'=>'trang','Hằng'=>'hang','Yến'=>'yen','Nhi'=>'nhi',
    'Quyên'=>'quyen','Vy'=>'vy','Châu'=>'chau','Giang'=>'giang',
    'Thanh'=>'thanh','Xuân'=>'xuan','Diễm'=>'diem','Nhung'=>'nhung',
    'Trâm'=>'tram','Thùy'=>'thuy','Diệu'=>'dieu','Lệ'=>'le2',
    'Hùng'=>'hung','Tuấn'=>'tuan','Quang'=>'quang','Nam'=>'nam',
    'Huy'=>'huy','Khoa'=>'khoa','Long'=>'long','Phúc'=>'phuc',
    'Dũng'=>'dung','Tài'=>'tai','Khôi'=>'khoi','Nhân'=>'nhan',
    'Thiện'=>'thien2','Thắng'=>'thang','Lâm'=>'lam','Sơn'=>'son',
    'Đạt'=>'dat','Phong'=>'phong','Thành'=>'thanh2','Kiên'=>'kien',
    'Vĩnh'=>'vinh','Hưng'=>'hung2','Kim'=>'kim','Tú'=>'tu',
  }.freeze

  def self.romanize(word)
    ROMANIZE[word] || word.downcase.unicode_normalize(:nfd).gsub(/[^a-z0-9]/, '').presence || 'x'
  end

  # ── Name generators ───────────────────────────────────────
  def self.vn_name(male: [true, false].sample)
    if male
      { name: "#{VN_LAST.sample} #{VN_MALE_MID.sample} #{VN_MALE_FIRST.sample}",
        slug: "#{romanize(VN_LAST.sample)}.#{romanize(VN_MALE_MID.sample)}.#{romanize(VN_MALE_FIRST.sample)}" }
    else
      { name: "#{VN_LAST.sample} #{VN_FEMALE_MID.sample} #{VN_FEMALE_FIRST.sample}",
        slug: "#{romanize(VN_LAST.sample)}.#{romanize(VN_FEMALE_MID.sample)}.#{romanize(VN_FEMALE_FIRST.sample)}" }
    end
  end

  def self.jp_name
    last  = JP_LAST.sample
    first = (JP_MALE_FIRST + JP_FEMALE_FIRST).sample
    { name: "#{last} #{first}", slug: "#{first.downcase}.#{last.downcase}" }
  end

  def self.en_name
    first = EN_FIRST.sample; last = EN_LAST.sample
    { name: "#{first} #{last}", slug: "#{first.downcase}.#{last.downcase}" }
  end

  def self.kr_name
    last = KR_LAST.sample; first = KR_FIRST.sample
    { name: "#{last} #{first}", slug: "#{first.downcase}#{last.downcase}" }
  end

  # ── Email builder ─────────────────────────────────────────
  PERSONAL_DOMAINS = %w[gmail.com yahoo.com hotmail.com outlook.com icloud.com].freeze
  JP_DOMAINS       = %w[gmail.com yahoo.co.jp hotmail.co.jp icloud.com].freeze
  KR_DOMAINS       = %w[gmail.com naver.com kakao.com].freeze

  @@used_emails = Set.new

  def self.used_emails; @@used_emails; end

  def self.unique_email(slug, domain_list = PERSONAL_DOMAINS)
    base  = slug.gsub(/[^a-z0-9]/, '.').squeeze('.').gsub(/\.$/, '')
    email = "#{base}@#{domain_list.sample}"
    n = 1
    while @@used_emails.include?(email)
      email = "#{base}#{n}@#{domain_list.sample}"
      n += 1
    end
    @@used_emails.add(email)
    email
  end

  # ── Time / date helpers ───────────────────────────────────
  def self.rand_time(from, to = NOW)
    Time.at(rand(from.to_i..to.to_i))
  end

  def self.rand_date(from, to = TODAY)
    Date.jd(rand(from.to_date.jd..to.to_date.jd))
  end

  def self.chance(pct); rand(100) < pct; end

  # ── Avatar / thumbnail helpers ────────────────────────────
  BG_COLORS = %w[0ea5e9 8b5cf6 ec4899 f59e0b 10b981 3b82f6 ef4444 6366f1 14b8a6 f97316].freeze

  def self.avatar(name)
    encoded = URI.encode_www_form_component(name.to_s.split.first(2).join(' '))
    "https://ui-avatars.com/api/?name=#{encoded}&background=#{BG_COLORS.sample}&color=fff&size=256&bold=true"
  end

  def self.thumbnail(seed_n)
    "https://picsum.photos/seed/course#{seed_n}/800/450"
  end

  # Real educational YouTube video IDs (publicly accessible)
  YT_IDS = %w[
    rfscVS0vtbw PkZNo7MFNFg W6NZfCO5SIk bMknfKXIFA8 aircAruvnKk
    8jLOx1hD3_o HXV3zeQKqGY Eo-KmOd3i7s fNk_sBjux38 KJgsSFOSQv0
    eIrMbAQSU34 Pt5IvIx3oik 4eURSPGDjpQ 3PHXvlpTkf8 YrtFtITXjtg
    F9UC9DY-vIU YufqhkYd7c8 ZnHmskwqedg t81Y7IzFxC8 HDFHxt3LHGE
    O8GlnTv78OY rwBkWqa4AHk VqgTr-tRmQU 5hSMY0Vkjfw PVKthhCDr7s
    2Vv-BfVoq4g h6CKBt3E2VE fis26HvvDII g_j6ILT-X0k ZJthWmMUweI
    A74TOX803D0 FHBkSamLPsg nGAK4J7jSWM oFJHOWfHC9c dHLOa9bBPCk
    ua-CiDNNj30 yfoY53QXEnI 9xoqXVjBEF8 c0bo64MQLno nCHu-Wqbu3A
    jS4aFq5-91g SLkMrJSx5KI lZcVFonRxBY 09L7B8iBHhk T98MPQHlQQ4
  ].freeze

  def self.yt_embed(n)
    "https://www.youtube.com/embed/#{YT_IDS[n % YT_IDS.length]}"
  end

  # ── Instructor bios ───────────────────────────────────────
  INSTRUCTOR_BIOS = [
    "With over 12 years of industry experience spanning software architecture, distributed systems, and team leadership, I have worked with organisations ranging from seed-stage startups to NASDAQ-listed tech companies. My teaching philosophy is simple: real skill comes from understanding the *why*, not just the *how*.",
    "Former principal engineer at a leading Tokyo-based internet company, now focused full-time on education. I have mentored 200+ engineers and led systems that serve tens of millions of users daily. I believe the gap between classroom and production is where most developers get stuck — my courses close that gap.",
    "PhD in Computer Science, 15+ publications in top-tier conferences, 8 years of industry R&D. I bridge academic rigour with the pragmatism that production systems demand. You will leave my courses with both the theory to understand deeply and the skills to build immediately.",
    "Certified Solutions Architect (AWS Professional, GCP Professional, Azure Expert) with experience designing infrastructure for healthcare, fintech, and e-commerce platforms. I have helped over 60 companies migrate and optimise cloud architecture. My courses focus on decisions that scale.",
    "10+ years teaching Japanese, English, and Korean to learners across Asia and beyond. Certified JLPT examiner and IELTS assessor. My approach is communicative-first: you learn language by using it, not memorising rules.",
    "CFA charterholder, former investment banker, and fintech advisor. I have worked on IPOs, M&A transactions, and portfolio construction for institutional clients. I translate the complexity of modern finance into frameworks anyone can apply.",
    "Full-stack developer, open source contributor, and co-founder of two bootstrapped SaaS products. I have been building Rails applications since version 4 and React since version 0.13. My courses prioritise production-grade patterns over toy examples.",
    "DevOps engineer and platform architect with experience at hyperscalers and enterprise banks. I have built zero-downtime deployment pipelines, reduced MTTR from hours to minutes, and trained engineering teams in modern reliability practices.",
    "Senior UX researcher and product designer with 11 years across design consultancies, product agencies, and in-house roles at Series B to post-IPO companies. I teach evidence-based methods that connect user behaviour to business outcomes.",
    "Data scientist and ML engineer who has shipped recommendation engines, fraud detection systems, and demand forecasting models to production. My background spans statistics, software engineering, and business intelligence.",
    "Backend developer specialised in high-throughput APIs and event-driven systems. Co-author of an open source Ruby gem with 2M+ monthly downloads. I teach how to think about systems before writing a single line of code.",
    "Marketing director turned growth consultant. I have managed $10M+ in annual ad spend across Google, Meta, and programmatic channels, and built content strategies that drive organic traffic for B2B SaaS products. Numbers-first, creativity-second.",
  ].freeze

  # ── Student bios ─────────────────────────────────────────
  STUDENT_BIOS = [
    "Software developer with 3 years of experience, always looking to deepen my skills in backend systems and cloud architecture.",
    "Career changer transitioning from accounting to data science. Using structured courses to build the technical foundation I need.",
    "Frontend developer expanding into full-stack. React is my comfort zone; I'm actively working on backend and DevOps skills.",
    "Recent computer science graduate refining practical skills that weren't covered in my university curriculum.",
    "Product manager with a technical background, upskilling to have better conversations with engineering teams.",
    "Freelance developer learning to deliver higher-quality, more maintainable code for my clients.",
    "Business analyst learning SQL, Python, and data visualisation to reduce dependency on the data team.",
    "Entrepreneur building my first SaaS product. Taking courses on Rails, payments, and growth.",
    "University student complementing my studies with practical, industry-relevant skills.",
    "Marketing professional learning analytics and automation to make my campaigns more measurable.",
    "QA engineer moving toward development. Courses on testing frameworks and CI/CD are my priority.",
    "Startup founder learning finance and fundraising to prepare for my seed round.",
    "IT administrator upskilling toward cloud and DevOps to stay relevant in a changing industry.",
    "Designer learning front-end development to prototype and ship my own design ideas.",
    "Teacher exploring EdTech tools and instructional design to improve my classroom outcomes.",
    "Data analyst working toward a machine learning specialisation, one course at a time.",
    "Japanese language learner at N3 level, aiming for N2 before applying for jobs in Japan.",
    "Infrastructure engineer studying for AWS Solutions Architect Professional certification.",
    "Mobile developer learning cross-platform frameworks to reduce the cost of building for iOS and Android.",
    "Junior developer using courses to catch up with senior colleagues and contribute more effectively.",
  ].freeze

  # ── Review texts ──────────────────────────────────────────
  REVIEWS = {
    5 => [
      "This course fundamentally changed how I approach this subject. The instructor does not just teach syntax — they teach reasoning. I have already applied the patterns at work and my team noticed the improvement.",
      "Best online course I have taken, full stop. Rigorous content, excellent pacing, and the instructor's depth of knowledge is evident in every lesson. Worth every yen.",
      "I was sceptical at first given the price point, but this course has paid for itself many times over. The capstone project alone was worth the investment.",
      "The instructor's explanation of complex topics is genuinely outstanding. Dense material, but never overwhelming. I revisit the reference sections regularly.",
      "This deserves to be in a university curriculum. The logical progression from fundamentals to advanced application is masterfully designed.",
      "Completed the course in three weeks. Got a promotion two months later. My manager specifically mentioned improvements in the exact skills this course covers.",
      "I have taken every major competing course on this topic. This one wins on depth, practical applicability, and instructor expertise. Not close.",
      "The exercises are challenging in the right way — they push you to apply concepts rather than copy code. By the end, you genuinely understand what you are doing.",
    ],
    4 => [
      "Very strong course overall. Comprehensive content and a knowledgeable instructor. I would like to see more hands-on exercises in the middle sections, but the fundamentals coverage is excellent.",
      "Great curriculum and production quality. Some minor audio issues in lessons 12–14, but the content itself is top-tier. Four stars with high confidence.",
      "The first two-thirds of the course are exceptional. The final section felt slightly rushed compared to the earlier modules. Still highly recommend.",
      "Solid, well-structured content that translated directly into practical improvements at work. Would benefit from more real-world case studies.",
      "Excellent theoretical grounding and the instructor explains difficult concepts clearly. Deducting one star only because some code examples use deprecated APIs.",
      "This course gave me a strong foundation I have been building on for months. A few more advanced exercises would make it perfect, but it is a great learning resource.",
      "The instructor clearly has deep expertise and explains it well. Pacing is good throughout. My only request would be more coverage of edge cases.",
    ],
    3 => [
      "Mixed feelings. The core content is solid and the instructor knows the material, but the course structure feels uneven — some topics are over-explained while others are rushed.",
      "Good for complete beginners but moves too quickly for anyone who needs to understand the *why* behind each concept. The prerequisites need to be clearer.",
      "The fundamentals section is excellent. The advanced topics feel underdeveloped. Three stars because the good content is genuinely good.",
      "Production quality is inconsistent across sections — some lessons have audio issues and the visual examples are unclear in a few places. The curriculum itself is fine.",
      "Decent course, but the Q&A response time is slow and some of my questions have been waiting weeks for an answer. Content is usable.",
    ],
    2 => [
      "The marketing material promised more than the course delivers. Several key topics are barely touched, and the practical examples feel contrived rather than realistic.",
      "The instructor has domain knowledge but struggles to communicate it effectively. I found myself relying on external resources more than the course material.",
      "Significantly outdated in several sections. Some code examples throw deprecation warnings or errors with current library versions.",
      "Too much lecture, not enough hands-on work. The quiz questions are too simple to verify real understanding of the material.",
    ],
    1 => [
      "Very disappointing for the price. The content is surface-level and could be found in any free tutorial. I do not feel I learned anything new.",
      "Poorly structured and in some sections factually incorrect. I cannot recommend this to anyone.",
    ],
  }.freeze

  # ── Comment bodies ────────────────────────────────────────
  COMMENTS = [
    "This lesson finally made it click for me. I had been stuck on this concept for weeks.",
    "Could someone help clarify the difference between the two approaches demonstrated here? I am not sure which to use in a production context.",
    "Minor note: there is a typo in the code example at 8:40 — the variable should be `result` not `res`. Still runs but might confuse newer learners.",
    "Implementing this in my current project as I watch. The real-world framing makes everything much clearer.",
    "For anyone struggling here: I found it helpful to pause, delete the example code, and rewrite it from scratch before continuing.",
    "Does this approach still work with the latest version? I am seeing a deprecation warning I do not see in the video.",
    "The instructor's explanation is clear, but I believe there is a more idiomatic solution using standard library methods — happy to share in the discussion.",
    "Five years of professional experience and I still learned something new from this lesson. That is rare.",
    "At 12:30 the instructor mentions an alternative pattern but does not elaborate. Can anyone point to resources on that approach?",
    "Spent two hours debugging before realising I had missed the note at 15:50 about environment variables. Worth pausing there.",
    "Applied this pattern to legacy code at work yesterday. The readability improvement was immediately obvious to my team.",
    "Windows users: adjust the path separators in the configuration examples. Everything else works as shown.",
    "The before-and-after comparison at the end of this lesson is the clearest explanation of this tradeoff I have ever seen.",
    "Just finished this module on my third attempt. It is challenging material but the scaffolding is well thought out.",
    "The quiz at the end of this section is genuinely well-designed — it tests conceptual understanding, not just recall.",
    "The resource file linked in the description returns a 404. Could the instructor share an updated link?",
    "Instructor response time in Q&A is impressive. Got a detailed reply within a day, which is rare at this scale.",
    "For those asking: yes, this concept applies in the same way to the framework we discussed two sections back.",
    "The breakdown at 22:00 comparing the two implementations is exactly what I needed to make the right architectural decision.",
    "Revisiting this lesson six months later — my understanding of it has completely changed now that I have more context. This is a well-layered course.",
  ].freeze

  # ── Bank data ─────────────────────────────────────────────
  BANKS = %w[Vietcombank Techcombank BIDV MB\ Bank VPBank TPBank ACB Sacombank HDBank SHB].freeze

  def self.setup!
    BCrypt::Engine.cost = BCrypt::Engine::MIN_COST
    ActiveRecord::Base.record_timestamps = false
    puts "  Helpers loaded (BCrypt cost: #{BCrypt::Engine.cost})"
  end
end
