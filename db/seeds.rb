require 'faker'

puts "Bắt đầu dọn dẹp dữ liệu cũ..."
models = [
  QuizAnswer, QuizAttempt, QuizQuestion, QuestionOption, Question, Quiz,
  Comment, Review, ProgressTracking, Enrollment, License, CartItem, Cart,
  WalletTransaction, PayoutRequest, Lesson, CourseModule, Course,
  Category, InstructorProfile, Profile, Wallet, User, Organization
]

models.each do |model|
  model.delete_all if ActiveRecord::Base.connection.table_exists?(model.table_name)
end

puts "Bắt đầu tạo dữ liệu mẫu..."

NUM_ORGS = 3
NUM_INSTRUCTORS = 10
NUM_STUDENTS = 50
NUM_CATEGORIES = 8
NUM_COURSES = 20
MODULES_PER_COURSE = 3
LESSONS_PER_MODULE = 3

ActiveRecord::Base.transaction do
  # ==========================================
  # 1. Tạo Organizations
  # ==========================================
  puts "Tạo Organizations..."
  valid_plans = Organization.respond_to?(:plans) ? Organization.plans.keys : [0, 1, 2]

  organizations = NUM_ORGS.times.map do
    Organization.create!(
      name: Faker::Company.unique.name,
      domain: Faker::Internet.unique.domain_name,
      plan: valid_plans.sample
    )
  end

  # ==========================================
  # 2. Tạo Users (Admins, Instructors, Students)
  # ==========================================
  puts "Tạo Users & Profiles & Wallets..."

  valid_genders = Profile.respond_to?(:genders) ? Profile.genders.keys : ["male", "female"]

  def create_user_with_extras(name, email, role, org = nil, valid_genders = ["male", "female"])
    user = User.create!(
      name: name,
      email: email,
      password: "password123",
      role: role,
      confirmed_at: Time.current,
      organization: org
    )

    # User's after_create hook already created a wallet and profile, so we just update them
    user.wallet.update!(balance: rand(0.0..5000.0).round(2)) if user.wallet

    if user.profile
      user.profile.update!(
        bio: Faker::Lorem.paragraph,
        phone: "0#{rand(100000000..999999999)}",
        gender: valid_genders.sample,
        dob: Faker::Date.birthday(min_age: 18, max_age: 65)
      )
    end
    user
  end

  # Admin
  admin = create_user_with_extras("Admin User", "admin@example.com", "admin", nil, valid_genders)

  # Instructors
  puts "Tạo Instructors..."
  valid_ins_status = InstructorProfile.respond_to?(:statuses) ? InstructorProfile.statuses.keys : ["pending", "approved"]

  instructors = NUM_INSTRUCTORS.times.map do |i|
    user = create_user_with_extras(Faker::Name.name, "instructor#{i+1}@example.com", "instructor", nil, valid_genders)

    InstructorProfile.create!(
      user: user,
      bio_detailed: Faker::Lorem.paragraphs(number: 3).join("\n"),
      linkedin_url: "https://linkedin.com/in/#{Faker::Internet.username}",
      cv_url: "https://example.com/cv.pdf",
      website_url: Faker::Internet.url,
      phone: "0#{rand(100000000..999999999)}",
      bank_name: "Vietcombank",
      bank_account_number: Faker::Bank.account_number(digits: 10),
      bank_account_name: user.name.upcase,
      status: valid_ins_status.sample
    )
    user
  end

  # Students
  puts "Tạo Students..."
  students = NUM_STUDENTS.times.map do |i|
    org = i.even? ? organizations.sample : nil
    create_user_with_extras(Faker::Name.name, "student#{i+1}@example.com", "student", org, valid_genders)
  end

  # ==========================================
  # 3. Tạo Categories
  # ==========================================
  puts "Tạo Categories..."
  parent_categories = 4.times.map do
    Category.create!(name: Faker::ProgrammingLanguage.unique.name, description: Faker::Lorem.sentence)
  end

  categories = parent_categories + (NUM_CATEGORIES - 4).times.map do
    Category.create!(
      name: Faker::Job.unique.field,
      description: Faker::Lorem.sentence,
      parent_id: parent_categories.sample.id
    )
  end

  # ==========================================
  # 4. Tạo Khóa học (Courses), Modules, Lessons & Quizzes
  # ==========================================
  puts "Tạo Courses, Modules, Lessons, Quizzes & Questions..."
  valid_course_status = Course.respond_to?(:statuses) ? Course.statuses.keys : [0, 1, 2]

  courses = NUM_COURSES.times.map do |i|
    thumbnail = "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&h=450&fit=crop&q=80&sig=#{i}"

    course = Course.create!(
      title: Faker::Educator.course_name + " " + Faker::App.version,
      description: Faker::Lorem.paragraphs(number: 4).join("\n"),
      category: categories.sample,
      created_by: instructors.sample.id,
      price: [0.0, 199000, 499000, 999000].sample,
      status: valid_course_status.sample,
      thumbnail_url: thumbnail
    )

    # Modules
    MODULES_PER_COURSE.times do |m_index|
      mod = CourseModule.create!(
        course: course,
        title: "Module #{m_index + 1}: #{Faker::Lorem.words(number: 3).join(' ')}",
        description: Faker::Lorem.sentence,
        order_index: m_index + 1
      )

      # Lessons
      LESSONS_PER_MODULE.times do |l_index|
        lesson = Lesson.create!(
          course_module: mod,
          title: "Bài #{l_index + 1}: #{Faker::Lorem.sentence(word_count: 4)}",
          description: Faker::Lorem.paragraph,
          video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          order_index: l_index + 1,
          free_preview: l_index == 0
        )

        # Comments
        rand(0..2).times do
          Comment.create!(
            user: students.sample,
            lesson: lesson,
            body: Faker::Lorem.sentence
          )
        end
      end
    end

    # Quizzes
    course_lessons = course.course_modules.flat_map(&:lessons)
    if course_lessons.any?
      quiz = Quiz.create!(
        course_id: course.id,
        lesson_id: course_lessons.last.id,
        title: "Bài kiểm tra: #{course.title}",
        description: "Vượt qua bài test này để hoàn thành khóa học.",
        total_questions: 5,
        time_limit: 15,
        created_by: course.created_by,
        pass_score: 80
      )

      5.times do |q_index|
        correct_index = rand(0..3)
        options_attrs = 4.times.map do |opt_index|
          {
            option_text: Faker::Lorem.words(number: 2).join(' '),
            is_correct: (opt_index == correct_index),
            option_order: opt_index + 1
          }
        end

        question = Question.create!(
          course_id: course.id,
          question_text: Faker::Lorem.question,
          question_type: "single",
          difficulty: ["easy", "medium", "hard"].sample,
          created_by: course.created_by,
          question_options_attributes: options_attrs
        )

        QuizQuestion.create!(quiz: quiz, question: question, order_index: q_index + 1)
      end
    end

    course
  end

  # ==========================================
  # 5. Tạo Enrollments, Licenses & Progress
  # ==========================================
  puts "Tạo Enrollments, Reviews & Progress..."

  valid_enrollment_status = Enrollment.respond_to?(:statuses) ? Enrollment.statuses.keys : ["active", "pending", "rejected"]
  valid_progress_status = ProgressTracking.respond_to?(:statuses) ? ProgressTracking.statuses.keys : ["not_started", "in_progress", "completed"]

  # Chỉ cho học viên enroll vào khóa học published
  published_courses = courses.select { |c| c.status == 'published' || c.status == 1 }
  published_courses = courses if published_courses.empty?

  students.each do |student|
    enrolled_courses = published_courses.sample(rand(2..6))

    enrolled_courses.each do |course|
      # Khóa primary key hoặc unique index trên user_id và course_id ở enrolments:
      next if Enrollment.exists?(user: student, course: course)

      Enrollment.create!(
        user: student,
        course: course,
        status: valid_enrollment_status.include?("active") ? "active" : valid_enrollment_status.sample,
        price: course.price,
        enrolled_at: Time.current
      )

      if [true, false].sample && !Review.exists?(user: student, course: course)
        Review.create!(
          user: student,
          course: course,
          rating: rand(3..5),
          content: Faker::Lorem.sentence
        )
      end

      # Progress
      course_lessons = course.course_modules.flat_map(&:lessons)
      next if course_lessons.empty?

      course_lessons.sample(rand(1..course_lessons.size)).each do |lesson|
        next if ProgressTracking.exists?(user: student, lesson: lesson)

        ProgressTracking.create!(
          user: student,
          course: course,
          lesson: lesson,
          progress_type: "lesson",
          status: valid_progress_status.sample,
          progress_value: rand(0.0..100.0).round(2)
        )
      end
    end
  end

  # ==========================================
  # 6. Giỏ hàng & Lịch sử giao dịch (Wallets, Carts)
  # ==========================================
  puts "Tạo dữ liệu giao dịch & Giỏ hàng..."
  students.first(15).each do |student|
    cart = Cart.find_or_create_by!(user: student)

    course_to_add = published_courses.sample
    unless CartItem.exists?(cart: cart, course: course_to_add) || Enrollment.exists?(user: student, course: course_to_add)
      CartItem.create!(
        cart: cart,
        course: course_to_add
      )
    end

    WalletTransaction.create!(
      wallet: student.wallet,
      amount: rand(100000.0..500000.0).round(2),
      transaction_type: 1, # DEPOSIT
      source_type: "Bank",
      source_id: 1
    )
  end

end

puts "🎉 Hoàn tất! Đã seed thành công cơ sở dữ liệu."
puts "Tài khoản Admin: admin@example.com / password123"
puts "Tài khoản Giáo viên mẫu: instructor1@example.com / password123"
puts "Tài khoản Học viên mẫu: student1@example.com / password123"
