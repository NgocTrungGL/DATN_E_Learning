# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_04_29_154614) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cart_items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "course_id"], name: "index_cart_items_on_cart_id_and_course_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["course_id"], name: "index_cart_items_on_course_id"
  end

  create_table "carts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "promo_code"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lesson_id", null: false
    t.text "body"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_comments_on_lesson_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "coupons", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code", null: false
    t.integer "discount_type", default: 0
    t.decimal "discount_value", precision: 10, scale: 2, null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer "target_type", default: 0
    t.bigint "course_id"
    t.bigint "creator_id", null: false
    t.integer "usage_limit", default: 0
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.index ["code"], name: "index_coupons_on_code", unique: true
    t.index ["course_id"], name: "index_coupons_on_course_id"
    t.index ["creator_id"], name: "index_coupons_on_creator_id"
  end

  create_table "course_modules", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.integer "order_index", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_modules_on_course_id"
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "category_id"
    t.string "title", null: false
    t.text "description"
    t.string "thumbnail_url"
    t.bigint "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.boolean "allow_admin_discounts", default: true
    t.index ["category_id"], name: "index_courses_on_category_id"
    t.index ["created_by"], name: "fk_rails_8984e96f9b"
    t.index ["status"], name: "index_courses_on_status"
  end

  create_table "enrollments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.timestamp "enrolled_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 15, scale: 2
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id", "course_id"], name: "index_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "instructor_profiles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio_detailed"
    t.string "linkedin_url"
    t.string "cv_url"
    t.string "website_url"
    t.string "bank_name"
    t.string "bank_account_number"
    t.string "bank_account_name"
    t.string "status", default: "pending", null: false
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.index ["user_id"], name: "index_instructor_profiles_on_user_id"
  end

  create_table "lessons", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_module_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.string "video_url"
    t.string "attachment_url"
    t.integer "order_index", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "free_preview", default: false
    t.index ["course_module_id"], name: "index_lessons_on_course_module_id"
  end

  create_table "licenses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "course_id", null: false
    t.bigint "user_id"
    t.string "code"
    t.integer "status", default: 0
    t.decimal "price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_licenses_on_course_id"
    t.index ["organization_id", "course_id", "status"], name: "index_licenses_on_organization_id_and_course_id_and_status"
    t.index ["organization_id"], name: "index_licenses_on_organization_id"
    t.index ["user_id"], name: "index_licenses_on_user_id"
  end

  create_table "organizations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "domain"
    t.integer "plan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_organizations_on_domain", unique: true
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "payout_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 15, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bank_name"
    t.string "bank_account_num"
    t.string "bank_account_name"
    t.index ["user_id"], name: "index_payout_requests_on_user_id"
  end

  create_table "profiles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.string "phone", limit: 20
    t.string "gender"
    t.date "dob"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "progress_trackings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.bigint "lesson_id"
    t.bigint "quiz_id"
    t.string "progress_type", null: false
    t.string "status", default: "not_started"
    t.decimal "progress_value", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_progress_trackings_on_course_id"
    t.index ["lesson_id"], name: "index_progress_trackings_on_lesson_id"
    t.index ["quiz_id"], name: "index_progress_trackings_on_quiz_id"
    t.index ["user_id", "lesson_id"], name: "index_progress_trackings_on_user_id_and_lesson_id", unique: true
    t.index ["user_id", "quiz_id"], name: "index_progress_trackings_on_user_id_and_quiz_id", unique: true
    t.index ["user_id"], name: "index_progress_trackings_on_user_id"
  end

  create_table "question_options", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.text "option_text", null: false
    t.boolean "is_correct", default: false
    t.integer "option_order", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "lesson_id"
    t.text "question_text", null: false
    t.string "question_type", default: "single"
    t.string "difficulty", default: "medium"
    t.bigint "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_questions_on_course_id"
    t.index ["created_by"], name: "index_questions_on_created_by"
    t.index ["lesson_id"], name: "index_questions_on_lesson_id"
  end

  create_table "quiz_answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_attempt_id", null: false
    t.bigint "question_id", null: false
    t.bigint "question_option_id"
    t.json "selected_option_ids"
    t.boolean "is_correct", default: false
    t.datetime "answered_at"
    t.decimal "score_earned", precision: 5, scale: 2, default: "0.0"
    t.index ["question_id"], name: "index_quiz_answers_on_question_id"
    t.index ["question_option_id"], name: "index_quiz_answers_on_question_option_id"
    t.index ["quiz_attempt_id"], name: "index_quiz_answers_on_quiz_attempt_id"
  end

  create_table "quiz_attempts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "user_id", null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.decimal "score", precision: 5, scale: 2
    t.boolean "is_passed", default: false
    t.string "status", default: "in_progress"
    t.integer "duration_seconds"
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quiz_questions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "question_id", null: false
    t.integer "order_index", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_quiz_questions_on_question_id"
    t.index ["quiz_id", "question_id"], name: "index_quiz_questions_on_quiz_id_and_question_id", unique: true
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quizzes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "lesson_id"
    t.string "title", limit: 200, null: false
    t.text "description"
    t.integer "total_questions", default: 10
    t.integer "time_limit"
    t.bigint "created_by"
    t.integer "pass_score", default: 70
    t.boolean "random_mode", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "easy_count", default: 0
    t.integer "medium_count", default: 0
    t.integer "hard_count", default: 0
    t.integer "scoring_type", default: 0
    t.index ["course_id"], name: "index_quizzes_on_course_id"
    t.index ["created_by"], name: "index_quizzes_on_created_by"
    t.index ["lesson_id"], name: "index_quizzes_on_lesson_id"
  end

  create_table "reviews", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.integer "rating"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_reviews_on_course_id"
    t.index ["user_id", "course_id"], name: "index_reviews_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "role", default: "student", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.bigint "organization_id"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wallet_transactions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "wallet_id", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.integer "transaction_type"
    t.string "source_type"
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "courses"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "comments", "lessons"
  add_foreign_key "comments", "users"
  add_foreign_key "coupons", "courses"
  add_foreign_key "coupons", "users", column: "creator_id"
  add_foreign_key "course_modules", "courses", on_delete: :cascade
  add_foreign_key "courses", "categories"
  add_foreign_key "courses", "users", column: "created_by", on_delete: :nullify
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users"
  add_foreign_key "instructor_profiles", "users"
  add_foreign_key "lessons", "course_modules", on_delete: :cascade
  add_foreign_key "licenses", "courses"
  add_foreign_key "licenses", "organizations"
  add_foreign_key "licenses", "users"
  add_foreign_key "payout_requests", "users"
  add_foreign_key "profiles", "users", on_delete: :cascade
  add_foreign_key "progress_trackings", "courses"
  add_foreign_key "progress_trackings", "lessons"
  add_foreign_key "progress_trackings", "quizzes"
  add_foreign_key "progress_trackings", "users"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "courses"
  add_foreign_key "questions", "lessons"
  add_foreign_key "questions", "users", column: "created_by"
  add_foreign_key "quiz_answers", "question_options"
  add_foreign_key "quiz_answers", "questions"
  add_foreign_key "quiz_answers", "quiz_attempts"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quiz_questions", "questions"
  add_foreign_key "quiz_questions", "quizzes"
  add_foreign_key "quizzes", "courses"
  add_foreign_key "quizzes", "lessons"
  add_foreign_key "quizzes", "users", column: "created_by"
  add_foreign_key "reviews", "courses"
  add_foreign_key "reviews", "users"
  add_foreign_key "users", "organizations"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "users"
end
