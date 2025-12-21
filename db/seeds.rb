# ADMIN_ID = 8
# TOTAL_COURSES = 20

# puts "🚀 Bắt đầu quá trình Seed dữ liệu..."

# # 1. Tìm Admin
# admin = User.find_by(id: ADMIN_ID)
# unless admin
#   puts "❌ LỖI: Không tìm thấy User ID #{ADMIN_ID}."
#   return
# end
# puts "✅ Admin: #{admin.name}"

# # 2. Categories
# puts "📂 Tạo Danh mục..."
# categories_data = [
#   { name: "Công nghệ thông tin", subs: ["Lập trình Web", "Data Science", "Mobile App"] },
#   { name: "Kinh doanh", subs: ["Digital Marketing", "Tài chính", "Nhân sự"] },
#   { name: "Thiết kế", subs: ["Đồ họa", "UI/UX", "3D"] }
# ]

# all_sub_categories = []
# categories_data.each do |cat_data|
#   parent = Category.find_or_create_by!(name: cat_data[:name])
#   cat_data[:subs].each do |sub_name|
#     sub = Category.find_or_create_by!(name: sub_name) { |s| s.parent = parent }
#     all_sub_categories << sub
#   end
# end

# # 3. Courses & Content
# puts "📚 Đang tạo #{TOTAL_COURSES} Khóa học..."

# topics = ["React", "Rails", "Python", "Excel", "Marketing", "AI", "Docker"]
# thumbnails = ["https://via.placeholder.com/400x225", "https://via.placeholder.com/400x225"]

# TOTAL_COURSES.times do |i|
#   # A. Tạo Khóa học
#   course = Course.new(
#     title: "#{topics.sample} Masterclass - K#{i+1}",
#     description: "Khóa học toàn diện từ A-Z.",
#     category: all_sub_categories.sample,
#     creator: admin, # <-- Đã sửa chuẩn
#     thumbnail_url: thumbnails.sample,
#     price: [0, 299000, 599000].sample
#   )
#   course.save!(validate: false) # Bỏ qua validation thừa nếu có

#   # B. Tạo Ngân hàng câu hỏi (10 câu)
#   questions = []
#   10.times do |q_idx|
#     q = Question.new(
#       course: course,
#       creator: admin,
#       question_text: "Câu hỏi trắc nghiệm #{q_idx + 1}?",
#       question_type: :single,
#       difficulty: :medium
#     )
#     q.save!(validate: false) # Lưu question trước để có ID

#     # Tạo đáp án
#     4.times do |opt_idx|
#       QuestionOption.create!(
#         question: q,
#         option_text: "Đáp án #{opt_idx + 1}",
#         is_correct: (opt_idx == 0),
#         option_order: opt_idx + 1
#       )
#     end
#     questions << q
#   end

#   # C. Modules & Lessons
#   3.times do |m_idx|
#     mod = CourseModule.create!(course: course, title: "Chương #{m_idx+1}", order_index: m_idx+1)

#     3.times do |l_idx|
#       lesson = Lesson.create!(
#         course_module: mod,
#         title: "Bài #{m_idx+1}.#{l_idx+1}",
#         video_url: "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
#         order_index: l_idx+1
#       )

#       # D. Mini Quiz (Gắn vào bài 2)
#       if l_idx == 1
#         mini_quiz = Quiz.new(
#           title: "Quiz bài #{l_idx+1}",
#           course: course,
#           lesson: lesson,
#           creator: admin,
#           total_questions: 3,
#           pass_score: 50
#         )
#         mini_quiz.save!(validate: false)

#         questions.sample(3).each { |q| QuizQuestion.create!(quiz: mini_quiz, question: q) }
#       end
#     end
#   end

#   # E. Big Quiz
#   big_quiz = Quiz.new(
#     title: "Thi cuối khóa",
#     course: course,
#     lesson: nil,
#     creator: admin,
#     total_questions: 10,
#     pass_score: 80
#   )
#   big_quiz.save!(validate: false)
#   questions.sample(10).each { |q| QuizQuestion.create!(quiz: big_quiz, question: q) }

#   print "."
# end

# puts "\n🎉 Seed thành công!"

puts "--- Đang tạo dữ liệu mẫu cho B2B ---"

admin = User.find_by(email: "nunu.cv@gmail.com")
org = admin.organization

course = Course.first

if org && course
  puts "Đang tạo 5 License cho công ty #{org.name} - Khóa học: #{course.title}"

  5.times do
    License.create!(
      organization: org,
      course: course,
      price: 100000, # Giá giả định
      status: :available,
      code: "TEST-#{SecureRandom.hex(4).upcase}"
    )
  end
  puts "-> Xong! Đã có 5 vé."
else
  puts "-> LỖI: Không tìm thấy Admin hoặc Khóa học để tạo License."
end
