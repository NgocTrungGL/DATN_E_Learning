# =============================================================================
# STEP 7: COURSES
# =============================================================================
step '(7/14) Creating courses, modules, lessons, quizzes, questions'

# Map category key to cat_map ID for course assignment
COURSE_CATEGORY_MAP = {
  'ML' => 'ML', 'DL' => 'DL', 'LLM' => 'LLM', 'PE' => 'PE',
  'CV' => 'CV', 'NLP' => 'NLP', 'AGENT' => 'AGENT', 'RAG' => 'RAG',
  'WEBDEV' => 'WEBDEV', 'FRONTEND' => 'FRONTEND', 'BACKEND' => 'BACKEND',
  'MOBILE' => 'MOBILE', 'DB' => 'DB', 'SECURITY' => 'SECURITY',
  'DEVOPSUB' => 'DEVOPSUB', 'CLOUD' => 'CLOUD', 'K8S' => 'K8S', 'IaC' => 'IaC',
  'PYTHON' => 'PYTHON', 'JSTYPE' => 'JSTYPE', 'GO' => 'GO', 'RUST' => 'RUST',
  'JAVA' => 'JAVA', 'RUBY' => 'RUBY',
  'ENG' => 'ENG', 'IELTS' => 'IELTS', 'JPN' => 'JPN', 'KOR' => 'KOR',
  'CHN' => 'CHN', 'BIZENG' => 'BIZENG',
  'DS' => 'DS', 'DE' => 'DE', 'BI' => 'BI', 'DA' => 'DA',
  'STOCKS' => 'STOCKS', 'TA' => 'TA', 'FA' => 'FA', 'PF' => 'PF', 'ACCTG' => 'ACCTG',
  'DMKTG' => 'DMKTG', 'SEO' => 'SEO', 'SMM' => 'SMM',
  'CONTENT' => 'CONTENT', 'BRAND' => 'BRAND',
  'UXUI' => 'UXUI', 'GDESIGN' => 'GDESIGN', 'MOTION' => 'MOTION', 'PDESIGN' => 'PDESIGN',
  'VIDED' => 'VIDED', 'PHOTO' => 'PHOTO',
  'PM' => 'PM', 'BIZSTRAT' => 'BIZSTRAT', 'PROJMGMT' => 'PROJMGMT', 'AGILE' => 'AGILE',
  'ROBOT' => 'ROBOT', 'IOT' => 'IOT',
  'COMM' => 'COMM', 'LEADER' => 'LEADER', 'MINDSET' => 'MINDSET',
}.freeze

# Determine question pool per category
CATEGORY_QUESTION_POOL = {
  %w[ML DL LLM PE CV NLP AGENT RAG WEBDEV FRONTEND BACKEND MOBILE DB SECURITY
     DEVOPSUB CLOUD K8S IaC PYTHON JSTYPE GO RUST JAVA RUBY DS DE BI DA] => :tech,
  %w[STOCKS TA FA PF ACCTG] => :finance,
  %w[ENG IELTS BIZENG] => :english,
  %w[JPN] => :japanese,
  %w[DMKTG SEO SMM CONTENT BRAND] => :marketing,
}.freeze

def questions_for(cat_key)
  CATEGORY_QUESTION_POOL.each do |keys, pool|
    return QUIZ_QUESTIONS[pool] if keys.include?(cat_key)
  end
  QUIZ_QUESTIONS[:tech]
end

def module_templates_for(cat_key)
  case cat_key
  when *%w[ML DL LLM PE CV NLP AGENT RAG DS DE BI DA] then TOPIC_MODULES[:ml]
  when *%w[WEBDEV FRONTEND BACKEND MOBILE DB SECURITY DEVOPSUB CLOUD K8S IaC PYTHON JSTYPE GO RUST JAVA RUBY] then TOPIC_MODULES[:web]
  when *%w[STOCKS TA FA PF ACCTG] then TOPIC_MODULES[:finance]
  when *%w[ENG IELTS BIZENG] then TOPIC_MODULES[:english]
  when *%w[JPN KOR CHN] then TOPIC_MODULES[:japanese]
  else TOPIC_MODULES[:web]
  end
end

approved_instructor_ids = InstructorProfile.where(status: 'approved').pluck(:user_id)
course_ids = []
course_cat_map = {}  # course_id => cat_key
course_instructor_map = {}  # course_id => instructor_id
course_price_map = {}  # course_id => price

cat_map = {}
CATEGORY_FLAT.each do |c|
  if c[:parent].nil?
    cat = Category.find_by(name: c[:name], parent_id: nil)
  else
    parent_c_flat = CATEGORY_FLAT.find { |pc| pc[:key] == c[:parent] }
    parent_cat = Category.find_by(name: parent_c_flat[:name], parent_id: nil) if parent_c_flat
    cat = Category.find_by(name: c[:name], parent_id: parent_cat&.id) if parent_cat
  end
  cat_map[c[:key]] = cat&.id if cat
end

course_seq = 0
COURSE_POOL.each do |cat_key, courses_data|
  cat_id = cat_map[COURSE_CATEGORY_MAP[cat_key]]
  next unless cat_id

  courses_data.each_with_index do |course_info, ci|
    title, subtitle = course_info
    inst_id = approved_instructor_ids[course_seq % approved_instructor_ids.size]
    price = case course_seq % 5
            when 0 then 0.0                          # free
            when 1 then [299_000, 399_000, 499_000][course_seq % 3].to_f / 100.0
            else       [699_000, 899_000, 1_299_000][course_seq % 3].to_f / 100.0
            end

    c = Course.create!(
      category_id:  cat_id,
      title:        title,
      description:  subtitle,
      thumbnail_url: THUMBNAIL_URLS[course_seq % THUMBNAIL_URLS.size],
      created_by:   inst_id,
      price:        price,
      status:       course_seq % 15 == 0 ? 0 : 2,   # 2 published, occasionally 0 draft
      allow_admin_discounts: course_seq % 5 != 0,
      created_at:   ts(rand(100..600)), updated_at: ts(rand(0..60))
    )

    course_ids << c.id
    course_cat_map[c.id] = cat_key
    course_instructor_map[c.id] = inst_id
    course_price_map[c.id] = price
    course_seq += 1
  end
end

ok(course_ids.size, 'courses')

# =============================================================================
# MODULES & LESSONS
# =============================================================================
step '  └─ Creating course modules and lessons'

module_rows  = []
lesson_rows  = []
mod_seq      = 0
lesson_seq   = 0

# We'll build module/lesson data, insert in batches, then fetch IDs
# Use a temp structure to track which course => module titles => lesson titles
course_module_plan = {}

course_ids.each do |cid|
  cat_key   = course_cat_map[cid]
  templates = module_templates_for(cat_key)
  inst_id   = course_instructor_map[cid]

  # Alternate between topic-specific templates and generic templates
  mod_templates = if mod_seq % 3 == 0
    # Use generic MODULE_LESSON_TEMPLATES
    MODULE_LESSON_TEMPLATES.values.sample(rand(5..7))
  else
    # Use topic templates + intro
    [MODULE_LESSON_TEMPLATES[:intro]] +
      templates.sample(rand(3..5)) +
      [MODULE_LESSON_TEMPLATES[:qa]]
  end

  course_module_plan[cid] = mod_templates
  mod_seq += 1
end

# Insert all modules at once, then fetch back IDs
course_ids.each_slice(50) do |batch_cids|
  batch_mods = []
  batch_cids.each do |cid|
    course_module_plan[cid].each_with_index do |tpl, oidx|
      batch_mods << {
        course_id:   cid,
        title:       tpl[:module],
        description: "Phần #{oidx + 1} của khóa học",
        order_index: oidx + 1,
        created_at:  ts(rand(50..500)), updated_at: ts(rand(0..30))
      }
    end
  end
  CourseModule.insert_all(batch_mods) unless batch_mods.empty?
end

ok(CourseModule.count, 'course_modules')

# Fetch all modules
all_modules = CourseModule.order(:course_id, :order_index).to_a
course_module_ids = {}  # course_id => [module_id, ...]
all_modules.each do |m|
  (course_module_ids[m.course_id] ||= []) << m.id
end

# Build and insert lessons
lesson_batch = []
all_modules.each_with_index do |mod, mi|
  cid     = mod.course_id
  cat_key = course_cat_map[cid]
  inst_id = course_instructor_map[cid]

  # Determine lesson titles for this module
  plan_idx = (course_module_ids[cid] || []).index(mod.id) || 0
  tpl_array= course_module_plan[cid]
  tpl      = tpl_array ? tpl_array[plan_idx] : MODULE_LESSON_TEMPLATES[:core1]
  lessons  = tpl ? tpl[:lessons] : ['Introduction', 'Core Concepts', 'Practice', 'Summary']

  lessons.each_with_index do |ltitle, li|
    yt_id = YOUTUBE_IDS[(mi * 7 + li) % YOUTUBE_IDS.size]
    lesson_batch << {
      course_module_id: mod.id,
      title:            ltitle,
      description:      "Bài #{li + 1}: #{ltitle}",
      video_url:        "https://www.youtube.com/watch?v=#{yt_id}",
      attachment_url:   li % 4 == 0 ? "https://cdn.edtech.vn/files/lesson_#{mod.id}_#{li}.pdf" : nil,
      order_index:      li + 1,
      free_preview:     li == 0,
      created_at:       ts(rand(50..500)), updated_at: ts(rand(0..20))
    }
    lesson_seq += 1
  end

  if lesson_batch.size >= 500
    Lesson.insert_all(lesson_batch)
    lesson_batch = []
  end
end
Lesson.insert_all(lesson_batch) unless lesson_batch.empty?

ok(Lesson.count, 'lessons')

# =============================================================================
# QUIZZES, QUESTIONS, QUESTION OPTIONS
# =============================================================================
step '  └─ Creating quizzes, questions and options'

all_lesson_ids = Lesson.order(:id).pluck(:id, :course_module_id).to_h { |lid, mid| [lid, mid] }
module_course_map = CourseModule.pluck(:id, :course_id).to_h

# Build quizzes: 2-4 per course
quiz_rows = []
course_ids.each_with_index do |cid, i|
  num_quizzes = rand(2..4)
  num_quizzes.times do |qi|
    quiz_rows << {
      course_id:       cid,
      lesson_id:       nil,
      title:           ["Quiz #{qi + 1}: Kiểm tra Kiến thức Chương #{qi + 1}",
                        "Bài kiểm tra Trắc nghiệm #{qi + 1}",
                        "Assessment #{qi + 1}: Core Concepts",
                        "Ôn tập và Đánh giá Phần #{qi + 1}"][qi % 4],
      description:     "Kiểm tra kiến thức sau khi học phần #{qi + 1} của khóa học.",
      total_questions: rand(10..15),
      time_limit:      [nil, 15, 20, 30][qi % 4],
      created_by:      course_instructor_map[cid],
      pass_score:      [60, 70, 75, 80][qi % 4],
      random_mode:     qi % 3 != 0,
      easy_count:      4, medium_count: 4, hard_count: 2,
      scoring_type:    0,
      created_at:      ts(rand(30..300)), updated_at: ts(rand(0..20))
    }
  end
end

Quiz.insert_all(quiz_rows)
ok(Quiz.count, 'quizzes')

# Build questions per course (pool of 15-20 questions each quiz can draw from)
all_quizzes = Quiz.select(:id, :course_id, :created_by).to_a
course_quiz_map = {}  # course_id => [quiz_id, ...]
all_quizzes.each { |q| (course_quiz_map[q.course_id] ||= []) << q.id }

question_rows    = []
q_option_rows    = []
quiz_q_rows      = []
q_global_idx     = 0

course_ids.each_with_index do |cid, ci|
  cat_key    = course_cat_map[cid]
  q_pool     = questions_for(cat_key)
  inst_id    = course_instructor_map[cid]
  quiz_list  = course_quiz_map[cid] || []

  # Create 15 questions per course from pool (cycling)
  course_question_ids_tmp = []
  15.times do |qi|
    q_data = q_pool[qi % q_pool.size]
    question_rows << {
      course_id:     cid,
      lesson_id:     nil,
      question_text: q_data[:q],
      question_type: 'single',
      difficulty:    q_data[:difficulty],
      created_by:    inst_id,
      created_at:    ts(rand(30..300)), updated_at: ts(rand(0..20))
    }
    course_question_ids_tmp << q_global_idx
    q_global_idx += 1
  end

  # We'll resolve actual IDs after insert; track by position
  # Also build options for each
  15.times do |qi|
    q_data = q_pool[qi % q_pool.size]
    q_data[:opts].each_with_index do |opt_text, oi|
      q_option_rows << {
        question_id: 0,        # placeholder — replaced after insert
        _q_idx:      ci * 15 + qi,  # internal tracking field (not a real column)
        option_text: opt_text,
        is_correct:  oi == q_data[:correct],
        option_order: oi + 1,
        created_at:  ts(rand(30..200)), updated_at: ts(rand(0..10))
      }
    end
  end
end

# Insert questions in batches
clean_q_rows = question_rows.map { |r| r.except(:_q_idx) }
batch_insert(Question, clean_q_rows)
ok(Question.count, 'questions')

# Fetch question IDs by (course_id, question_text) — build mapping
all_questions = Question.select(:id, :course_id).order(:id).to_a
course_question_id_map = {}  # course_id => [q_id, q_id, ...]
all_questions.each { |q| (course_question_id_map[q.course_id] ||= []) << q.id }

# Fix question_option_rows placeholder IDs
clean_option_rows = []
course_ids.each_with_index do |cid, ci|
  q_ids = course_question_id_map[cid] || []
  15.times do |qi|
    next if qi >= q_ids.size
    actual_q_id = q_ids[qi]
    q_data = questions_for(course_cat_map[cid])[qi % questions_for(course_cat_map[cid]).size]
    q_data[:opts].each_with_index do |opt_text, oi|
      clean_option_rows << {
        question_id: actual_q_id,
        option_text: opt_text,
        is_correct:  oi == q_data[:correct],
        option_order: oi + 1,
        created_at:  ts(rand(30..200)), updated_at: ts(rand(0..10))
      }
    end
  end
end

batch_insert(QuestionOption, clean_option_rows)
ok(QuestionOption.count, 'question_options')

# Build quiz_questions (assign 10 questions per quiz from the 15-question pool)
course_ids.each do |cid|
  q_ids     = course_question_id_map[cid] || []
  quiz_list = course_quiz_map[cid] || []
  next if q_ids.empty? || quiz_list.empty?

  quiz_q_batch = []
  quiz_list.each_with_index do |qz_id, qi|
    # Each quiz gets a different window of 10 questions from the 15-q pool
    start_idx = (qi * 5) % [q_ids.size - 10, 0].max.clamp(0, 5)
    selected  = q_ids.rotate(start_idx).first(10)
    selected.each_with_index do |q_id, oi|
      quiz_q_batch << {
        quiz_id:     qz_id,
        question_id: q_id,
        order_index: oi + 1,
        created_at:  ts(rand(20..200)), updated_at: ts(rand(0..10))
      }
    end
  end
  QuizQuestion.insert_all(quiz_q_batch) unless quiz_q_batch.empty?
end

ok(QuizQuestion.count, 'quiz_questions')
