# db/seeds.rb

puts "--- Bắt đầu Seeding dữ liệu tối giản ---"

# 1. Xóa dữ liệu cũ để tránh xung đột
puts "Cleaning database..."
ActiveRecord::Base.connection.disable_referential_integrity do
  models = [
    PayoutRequest, WalletTransaction, Wallet, Review, QuizAnswer, QuizAttempt,
    QuizQuestion, QuestionOption, Question, Quiz, ProgressTracking, Enrollment,
    Lesson, CourseModule, Course, Category, CartItem, Cart, InstructorProfile,
    Profile, User, Organization
  ]

  models.each do |model|
    if Object.const_defined?(model.name)
      model.delete_all
    end
  end
end

# 2. Tạo Tổ chức (Bắt buộc nếu User belongs_to Organization)
puts "Creating organization..."
org = Organization.find_or_create_by!(domain: "awesome.edu") do |o|
  o.name = "Awesome Academy"
  o.plan = 1
end

# 3. Tạo 2 tài khoản mẫu
puts "Creating users..."
common_pass = "123456"

# Tài khoản Admin
admin = User.create!(
  name: "Ngoc Trung Admin",
  email: "admin@example.com",
  password: common_pass,
  password_confirmation: common_pass,
  role: "admin",
  confirmed_at: Time.current,
  organization: org
)

# Tài khoản User (Student)
student = User.create!(
  name: "Ngoc Trung Student",
  email: "student@example.com",
  password: common_pass,
  password_confirmation: common_pass,
  role: "student",
  confirmed_at: Time.current,
  organization: org
)

# 4. Tạo Profile và Wallet mặc định (để vào app không bị lỗi giao diện)
puts "Creating default profiles & wallets..."
[admin, student].each do |user|
  Profile.find_or_create_by!(user: user) do |p|
    p.bio = "Chào mừng #{user.name} đến với hệ thống."
    p.phone = "0123456789"
  end

  Wallet.find_or_create_by!(user: user) do |w|
    w.balance = 0
  end
end

puts "--- Seeding hoàn tất! 🚀 ---"
puts "Admin: admin@example.com / 123456"
puts "Student: student@example.com / 123456"
