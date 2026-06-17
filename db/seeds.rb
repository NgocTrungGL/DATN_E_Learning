# frozen_string_literal: true
# ============================================================
# db/seeds.rb — Production Seed Data for EdTech Platform
# ============================================================
# Usage:    rails db:seed
# Reset:    rails db:reset && rails db:seed
# Requires: bcrypt gem (already in Gemfile with Devise)
# ============================================================

require 'bcrypt'
require 'securerandom'
require 'set'

Dir[Rails.root.join('db/seeds/*.rb')].sort.each { |f| require f }

puts "\n🌱  Production Seed Data Generator"
puts "=" * 60

ActiveRecord::Base.transaction do
  SeedHelpers.setup!

  puts "\n[1/10] Organizations & Users..."
  SeedOrganizationsAndUsers.run!

  puts "\n[2/10] Categories..."
  SeedCategories.run!

  puts "\n[3/10] Courses & Content..."
  SeedCoursesAndContent.run!

  puts "\n[4/10] Quizzes & Questions..."
  SeedQuizzes.run!

  puts "\n[5/10] Enrollments, Licenses & Coupons..."
  SeedEnrollments.run!

  puts "\n[6/10] Reviews & Comments..."
  SeedReviewsAndComments.run!

  puts "\n[7/10] Progress Tracking & Quiz Attempts..."
  SeedProgress.run!

  puts "\n[8/10] Learning Activities, Streaks & Goals..."
  SeedLearningActivities.run!

  puts "\n[9/10] Certificates, Wallets & Notifications..."
  SeedCertificatesAndWallets.run!

  puts "\n[10/10] Discussions, Study Plans & Recommendations..."
  SeedMisc.run!
end

puts "\n" + "=" * 60
puts "✅  Seed complete!"
puts "-" * 60
puts "   Users total:     #{User.count}"
puts "   → Admins:        #{User.where(role: 'admin').count}"
puts "   → Instructors:   #{User.where(role: 'instructor').count}"
puts "   → Students:      #{User.where(role: 'student').count}"
puts "   Categories:      #{Category.count}"
puts "   Courses:         #{Course.count} (#{Course.published.count} published)"
puts "   Modules:         #{CourseModule.count}"
puts "   Lessons:         #{Lesson.count}"
puts "   Quizzes:         #{Quiz.count}"
puts "   Questions:       #{Question.count}"
puts "   Enrollments:     #{Enrollment.count}"
puts "   Reviews:         #{Review.count}"
puts "   Comments:        #{Comment.count}"
puts "   Activities:      #{LearningActivity.count}"
puts "   Certificates:    #{Certificate.count}"
puts "   Study Plans:     #{StudyPlan.count}"
puts "=" * 60

# ── Quick-activate command (idempotent) ───────────────────
puts "\n💡 All users pre-confirmed. Run this to activate any stragglers:"
puts "   User.update_all(confirmed_at: Time.current)"
