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

ActiveRecord::Schema[7.0].define(version: 2026_06_20_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "course_id"], name: "index_cart_items_on_cart_id_and_course_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["course_id"], name: "index_cart_items_on_course_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "promo_code"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.string "certificate_code", null: false
    t.datetime "issued_at", null: false
    t.string "template_type", default: "classic"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_code"], name: "index_certificates_on_certificate_code", unique: true
    t.index ["course_id"], name: "index_certificates_on_course_id"
    t.index ["user_id", "course_id"], name: "index_certificates_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_certificates_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lesson_id", null: false
    t.text "body"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_comments_on_lesson_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "coupons", force: :cascade do |t|
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

  create_table "course_embeddings", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.jsonb "embedding", default: [], null: false
    t.string "content_hash", null: false
    t.datetime "embedded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_hash"], name: "index_course_embeddings_on_content_hash"
    t.index ["course_id"], name: "index_course_embeddings_on_course_id"
  end

  create_table "course_learning_outcomes", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.string "content", null: false
    t.integer "order_index", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "order_index"], name: "index_course_learning_outcomes_on_course_id_and_order_index"
    t.index ["course_id"], name: "index_course_learning_outcomes_on_course_id"
  end

  create_table "course_modules", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.integer "order_index", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_modules_on_course_id"
  end

  create_table "course_similarities", force: :cascade do |t|
    t.bigint "course_a_id", null: false
    t.bigint "course_b_id", null: false
    t.decimal "score", precision: 8, scale: 6, null: false
    t.datetime "computed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_a_id", "course_b_id"], name: "index_course_similarities_on_course_a_id_and_course_b_id", unique: true
    t.index ["course_a_id", "score"], name: "index_course_similarities_on_course_a_id_and_score"
  end

  create_table "courses", force: :cascade do |t|
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
    t.index ["status"], name: "index_courses_on_status"
  end

  create_table "discussion_messages", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.integer "replies_count", default: 0, null: false
    t.index ["course_id", "created_at"], name: "index_discussion_messages_on_course_id_and_created_at"
    t.index ["course_id"], name: "index_discussion_messages_on_course_id"
    t.index ["parent_id"], name: "index_discussion_messages_on_parent_id"
    t.index ["user_id"], name: "index_discussion_messages_on_user_id"
  end

  create_table "discussion_posts", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.boolean "pinned", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.integer "replies_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "pinned", "updated_at"], name: "idx_discussion_posts_course_pinned_updated"
    t.index ["course_id"], name: "index_discussion_posts_on_course_id"
    t.index ["user_id"], name: "index_discussion_posts_on_user_id"
  end

  create_table "discussion_replies", force: :cascade do |t|
    t.bigint "discussion_post_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_post_id"], name: "index_discussion_replies_on_discussion_post_id"
    t.index ["parent_id"], name: "index_discussion_replies_on_parent_id"
    t.index ["user_id"], name: "index_discussion_replies_on_user_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.datetime "enrolled_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 15, scale: 2
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id", "course_id"], name: "index_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "instructor_profiles", force: :cascade do |t|
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

  create_table "invoices", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "course_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.string "stripe_session_id"
    t.string "stripe_payment_intent"
    t.integer "status", default: 0
    t.string "invoice_number"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_invoices_on_course_id"
    t.index ["organization_id", "created_at"], name: "index_invoices_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_invoices_on_organization_id"
    t.index ["stripe_session_id"], name: "index_invoices_on_stripe_session_id"
  end

  create_table "learning_activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id"
    t.bigint "lesson_id"
    t.string "activity_type", null: false
    t.integer "duration_seconds", default: 0
    t.integer "score"
    t.date "activity_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_learning_activities_on_course_id"
    t.index ["lesson_id"], name: "index_learning_activities_on_lesson_id"
    t.index ["user_id", "activity_date"], name: "index_learning_activities_on_user_id_and_activity_date"
    t.index ["user_id", "activity_type"], name: "index_learning_activities_on_user_id_and_activity_type"
    t.index ["user_id"], name: "index_learning_activities_on_user_id"
  end

  create_table "learning_goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "goal_type", null: false
    t.integer "target_value", null: false
    t.integer "current_value", default: 0
    t.date "week_start", null: false
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "week_start", "goal_type"], name: "index_learning_goals_on_user_id_and_week_start_and_goal_type", unique: true
    t.index ["user_id"], name: "index_learning_goals_on_user_id"
  end

  create_table "learning_streaks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "current_streak", default: 0
    t.integer "longest_streak", default: 0
    t.date "last_activity_date"
    t.integer "weekly_activity_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_learning_streaks_on_user_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.bigint "course_module_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.string "video_url"
    t.string "attachment_url"
    t.integer "order_index", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "free_preview", default: false
    t.integer "lesson_type"
    t.text "content"
    t.json "resources"
    t.integer "upload_type", default: 0, null: false
    t.string "document_url"
    t.integer "cached_duration_seconds"
    t.index ["course_module_id"], name: "index_lessons_on_course_module_id"
    t.index ["upload_type"], name: "index_lessons_on_upload_type"
  end

  create_table "licenses", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "course_id", null: false
    t.bigint "user_id"
    t.string "code"
    t.integer "status", default: 0
    t.decimal "price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.bigint "invoice_id"
    t.index ["course_id"], name: "index_licenses_on_course_id"
    t.index ["invoice_id"], name: "index_licenses_on_invoice_id"
    t.index ["organization_id", "course_id", "status"], name: "index_licenses_on_organization_id_and_course_id_and_status"
    t.index ["organization_id"], name: "index_licenses_on_organization_id"
    t.index ["user_id"], name: "index_licenses_on_user_id"
  end

  create_table "message_reactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "discussion_message_id", null: false
    t.string "emoji", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_message_id"], name: "index_message_reactions_on_discussion_message_id"
    t.index ["user_id", "discussion_message_id", "emoji"], name: "index_msg_reactions_on_user_and_msg_and_emoji", unique: true
    t.index ["user_id"], name: "index_message_reactions_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lesson_id", null: false
    t.bigint "course_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_notes_on_course_id"
    t.index ["lesson_id"], name: "index_notes_on_lesson_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "body"
    t.string "notification_type"
    t.datetime "read_at"
    t.string "actionable_type", null: false
    t.bigint "actionable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actionable_type", "actionable_id"], name: "index_notifications_on_actionable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "domain"
    t.integer "plan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_organizations_on_domain", unique: true
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "payout_requests", force: :cascade do |t|
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

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.string "phone", limit: 20
    t.string "gender"
    t.date "dob"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "progress_trackings", force: :cascade do |t|
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

  create_table "question_options", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.text "option_text", null: false
    t.boolean "is_correct", default: false
    t.integer "option_order", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
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

  create_table "quiz_answers", force: :cascade do |t|
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

  create_table "quiz_attempts", force: :cascade do |t|
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

  create_table "quiz_questions", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "question_id", null: false
    t.integer "order_index", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_quiz_questions_on_question_id"
    t.index ["quiz_id", "question_id"], name: "index_quiz_questions_on_quiz_id_and_question_id", unique: true
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quizzes", force: :cascade do |t|
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

  create_table "reviews", force: :cascade do |t|
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

  create_table "study_plan_adjustments", force: :cascade do |t|
    t.bigint "study_plan_id", null: false
    t.string "reason"
    t.date "old_target_date"
    t.date "new_target_date"
    t.json "replanned_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["study_plan_id", "created_at"], name: "index_study_plan_adjustments_on_study_plan_id_and_created_at"
    t.index ["study_plan_id"], name: "index_study_plan_adjustments_on_study_plan_id"
  end

  create_table "study_plan_items", force: :cascade do |t|
    t.bigint "study_plan_id", null: false
    t.bigint "lesson_id", null: false
    t.date "scheduled_date"
    t.time "scheduled_start_time"
    t.integer "estimated_duration_minutes"
    t.integer "order_in_course"
    t.string "status", default: "pending"
    t.datetime "actual_completed_at"
    t.boolean "is_replan_needed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_study_plan_items_on_lesson_id"
    t.index ["study_plan_id", "scheduled_date"], name: "index_study_plan_items_on_study_plan_id_and_scheduled_date"
    t.index ["study_plan_id", "status"], name: "index_study_plan_items_on_study_plan_id_and_status"
    t.index ["study_plan_id"], name: "index_study_plan_items_on_study_plan_id"
  end

  create_table "study_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.date "goal_deadline"
    t.integer "target_days"
    t.json "preferred_study_times"
    t.string "status", default: "active"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_study_plans_on_course_id"
    t.index ["user_id", "course_id"], name: "index_study_plans_on_user_id_and_course_id", unique: true
    t.index ["user_id", "status"], name: "index_study_plans_on_user_id_and_status"
    t.index ["user_id"], name: "index_study_plans_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "plan_type", default: 0, null: false
    t.string "status", default: "active", null: false
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "canceled_at"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
  end

  create_table "user_recommendations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.decimal "score", precision: 8, scale: 4
    t.string "reason_type"
    t.datetime "computed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "course_id"], name: "index_user_recommendations_on_user_id_and_course_id", unique: true
    t.index ["user_id", "score"], name: "index_user_recommendations_on_user_id_and_score"
  end

  create_table "users", force: :cascade do |t|
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

  create_table "wallet_transactions", force: :cascade do |t|
    t.bigint "wallet_id", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.integer "transaction_type"
    t.string "source_type"
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_reference"
    t.index ["external_reference"], name: "index_wallet_transactions_on_external_reference", unique: true
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id", unique: true
  end

  create_table "wishlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_wishlists_on_course_id"
    t.index ["user_id", "course_id"], name: "index_wishlists_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_wishlists_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "courses"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "certificates", "courses"
  add_foreign_key "certificates", "users"
  add_foreign_key "comments", "lessons"
  add_foreign_key "comments", "users"
  add_foreign_key "coupons", "courses"
  add_foreign_key "coupons", "users", column: "creator_id"
  add_foreign_key "course_embeddings", "courses", on_delete: :cascade
  add_foreign_key "course_learning_outcomes", "courses"
  add_foreign_key "course_modules", "courses", on_delete: :cascade
  add_foreign_key "course_similarities", "courses", column: "course_a_id", on_delete: :cascade
  add_foreign_key "course_similarities", "courses", column: "course_b_id", on_delete: :cascade
  add_foreign_key "courses", "categories"
  add_foreign_key "courses", "users", column: "created_by", on_delete: :nullify
  add_foreign_key "discussion_messages", "courses"
  add_foreign_key "discussion_messages", "users"
  add_foreign_key "discussion_posts", "courses"
  add_foreign_key "discussion_posts", "users"
  add_foreign_key "discussion_replies", "discussion_posts"
  add_foreign_key "discussion_replies", "discussion_replies", column: "parent_id"
  add_foreign_key "discussion_replies", "users"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users"
  add_foreign_key "instructor_profiles", "users"
  add_foreign_key "invoices", "courses"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "learning_activities", "courses"
  add_foreign_key "learning_activities", "lessons"
  add_foreign_key "learning_activities", "users"
  add_foreign_key "learning_goals", "users"
  add_foreign_key "learning_streaks", "users"
  add_foreign_key "lessons", "course_modules", on_delete: :cascade
  add_foreign_key "licenses", "courses"
  add_foreign_key "licenses", "invoices"
  add_foreign_key "licenses", "organizations"
  add_foreign_key "licenses", "users"
  add_foreign_key "message_reactions", "discussion_messages"
  add_foreign_key "message_reactions", "users"
  add_foreign_key "notes", "courses"
  add_foreign_key "notes", "lessons"
  add_foreign_key "notes", "users"
  add_foreign_key "notifications", "users"
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
  add_foreign_key "study_plan_adjustments", "study_plans"
  add_foreign_key "study_plan_items", "lessons"
  add_foreign_key "study_plan_items", "study_plans"
  add_foreign_key "study_plans", "courses"
  add_foreign_key "study_plans", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_recommendations", "courses", on_delete: :cascade
  add_foreign_key "user_recommendations", "users", on_delete: :cascade
  add_foreign_key "users", "organizations"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "users"
  add_foreign_key "wishlists", "courses"
  add_foreign_key "wishlists", "users"
end
