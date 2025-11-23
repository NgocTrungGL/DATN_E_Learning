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

ActiveRecord::Schema[7.0].define(version: 2025_11_18_035452) do
  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
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
    t.index ["category_id"], name: "index_courses_on_category_id"
    t.index ["created_by"], name: "fk_rails_8984e96f9b"
  end

  create_table "enrollments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.timestamp "enrolled_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id", "course_id"], name: "index_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
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
    t.index ["course_module_id"], name: "index_lessons_on_course_module_id"
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
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_questions_on_course_id"
    t.index ["creator_id"], name: "index_questions_on_creator_id"
    t.index ["lesson_id"], name: "index_questions_on_lesson_id"
  end

  create_table "quiz_answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_attempt_id", null: false
    t.bigint "question_id", null: false
    t.bigint "question_option_id"
    t.json "selected_option_ids"
    t.boolean "is_correct", default: false
    t.datetime "answered_at"
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
    t.bigint "lesson_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.integer "total_questions", default: 10
    t.integer "time_limit"
    t.bigint "creator_id"
    t.integer "pass_score", default: 70
    t.boolean "random_mode", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_quizzes_on_course_id"
    t.index ["creator_id"], name: "index_quizzes_on_creator_id"
    t.index ["lesson_id"], name: "index_quizzes_on_lesson_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "course_modules", "courses", on_delete: :cascade
  add_foreign_key "courses", "categories"
  add_foreign_key "courses", "users", column: "created_by", on_delete: :nullify
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users"
  add_foreign_key "lessons", "course_modules", on_delete: :cascade
  add_foreign_key "profiles", "users", on_delete: :cascade
  add_foreign_key "progress_trackings", "courses"
  add_foreign_key "progress_trackings", "lessons"
  add_foreign_key "progress_trackings", "quizzes"
  add_foreign_key "progress_trackings", "users"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "courses"
  add_foreign_key "questions", "lessons"
  add_foreign_key "questions", "users", column: "creator_id"
  add_foreign_key "quiz_answers", "question_options"
  add_foreign_key "quiz_answers", "questions"
  add_foreign_key "quiz_answers", "quiz_attempts"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quiz_questions", "questions"
  add_foreign_key "quiz_questions", "quizzes"
  add_foreign_key "quizzes", "courses"
  add_foreign_key "quizzes", "lessons"
  add_foreign_key "quizzes", "users", column: "creator_id"
end
