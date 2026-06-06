# frozen_string_literal: true
# =============================================================================
# db/seeds.rb — EDTECH PLATFORM · Production-Grade Seed Data
# =============================================================================
#
#   bundle exec rails db:seed
#
#   Runtime:  ~25–45 min depending on hardware
#   Rails:    7.0  |  Ruby >= 2.7  |  MySQL 8.0 (utf8mb4)
#
#   Scale:
#     Users              ~5,011  (1 admin · 10 B2B · 200 instructors · 4,800 students)
#     Categories         ~130    (22 main + ~108 sub)
#     Courses            ~510+
#     Modules / Lessons  ~3,500 / ~22,000
#     Enrollments        ~65,000
#     Reviews            ~12,000
#     Comments           ~55,000
#     Progress trackings ~300,000+
#     All other tables   fully populated
#
#   Demo credentials (all accounts use same password):
#     Admin:       admin@edtech.dev
#     Instructor:  nguyen.minh.duc@gmail.com
#     Student:     (any generated student email)
#     B2B:         learning-admin@zigexn.vn
#     Password:    Demo@12345!
#
#   Structure:
#     seeds_part1.rb  —  Helpers, constants, data arrays (names, review text, comments)
#     seeds_part2.rb  —  Category definitions + Course title pool (510+ courses)
#     seeds_part3.rb  —  Quiz question pools + Module/lesson templates + Media assets
#     seeds_part4.rb  —  Steps  0–6  : Truncate · Org · Users · Profiles · Wallets
#                                       Subscriptions · InstructorProfiles · Categories
#     seeds_part5.rb  —  Step   7    : Courses · Modules · Lessons · Quizzes
#                                       Questions · QuestionOptions · QuizQuestions
#     seeds_part6.rb  —  Steps  8–9  : Enrollments · Progress Trackings
#     seeds_part7.rb  —  Steps 10–12 : Reviews · Quiz Attempts · Quiz Answers · Certificates
#     seeds_part8.rb  —  Steps 13–14 : Comments · Discussion Posts/Replies/Messages
#     seeds_part9.rb  —  Steps 15–16 : Notes · Wishlists · Carts · Coupons
#                                       Wallet Transactions · Payout Requests
#                                       Notifications · Course Similarities
#                                       User Recommendations · Message Reactions
#                                       Licenses · Invoices · Final Activation
# =============================================================================

SEED_DIR = __dir__   # same directory as this file (db/)

def load_seed_part(filename)
  path = File.join(SEED_DIR, filename)
  puts "\n#{'=' * 72}"
  puts "  Loading #{filename}"
  puts "  #{'-' * 68}"
  $stdout.flush
  load path
end

# Parts must be loaded in order — later parts query data created by earlier ones.
load_seed_part 'seeds_part1.rb'
load_seed_part 'seeds_part2.rb'
load_seed_part 'seeds_part3.rb'
load_seed_part 'seeds_part4.rb'
load_seed_part 'seeds_part5.rb'
load_seed_part 'seeds_part6.rb'
load_seed_part 'seeds_part7.rb'
load_seed_part 'seeds_part8.rb'
load_seed_part 'seeds_part9.rb'
