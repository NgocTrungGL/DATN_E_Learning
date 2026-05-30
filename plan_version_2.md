# Kế Hoạch Phát Triển E-Learning V2
**Phiên bản:** 2.0 — Post-Audit Toàn Diện
**Ngày:** 25/05/2026
**Trạng thái:** Bản nháp, chờ duyệt

---

## I. Tổng Quan Hệ Thống Hiện Tại

### 1.1 Điểm Mạnh Đã Xây Dựng

| Thành phần | Đánh giá | Chi tiết |
|------------|----------|----------|
| Phân quyền 6 vai trò | Tốt | Devise + CanCanCan, 36 models |
| Thanh toán Stripe | Hoàn thiện | Single/cart/license checkout + webhook |
| Quiz nâng cao | Hoàn thiện | Random generation, difficulty, time limit, weighted scoring |
| Revenue split 70/30 | Hoàn thiện | Tự động qua DistributeRevenueService |
| UI/Bootstrap + SCSS | Tốt | 48 SCSS files, 7-1 pattern, BEM |
| Turbo + Stimulus | Hoàn thiện | 16 Stimulus controllers, Turbo streams |
| Course lifecycle | Hoàn thiện | Draft → Pending → Published/Rejected |
| B2B cơ bản | Cơ bản | Organization, License, Employee, CourseMarket |
| Instructor workflow | Hoàn thiện | Registration → Admin approve → Create content |
| Search (Ransack) | Cơ bản | Filter theo category/price/rating |

### 1.2 Số Liệu Codebase

| Chỉ số | Giá trị |
|---------|---------|
| Models | 36 |
| Database tables | 35 |
| Controllers (total) | 63 |
| Views (ERB/Slim) | ~185 |
| SCSS files | 48 |
| JavaScript files | 19 |
| Stimulus controllers | 16 |
| Gems | 20 |
| Locales | 3 files (vi, en, devise.en) |

---

## II. Các Vấn Đề Kỹ Thuật Cần Sửa Ngay (Critical)

> [!CAUTION]
> Những vấn đề này ảnh hưởng trực tiếp đến security, stability hoặc performance. Cần fix trước mọi feature mới.

### C1. Test Coverage: 0%

**Mức độ:** Nghiêm trọng
**Effort:** Rất cao

Hiện tại không có bất kỳ file test nào trong `spec/`. Không có `rspec-rails` trong Gemfile.

```
Gap hiện tại:
- 0 RSpec tests
- 0 system tests
- 0 controller tests
- 0 model tests
- CI chỉ chạy RuboCop linting
```

**Hành động:**
1. Thêm `rspec-rails`, `factory_bot_rails`, `faker`, `shoulda-matchers`, `simplecov` vào Gemfile
2. Setup `spec/spec_helper.rb`, `spec/rails_helper.rb`
3. Viết tests cho critical paths:
   - Authentication (Devise flows)
   - Authorization (CanCanCan)
   - Enrollment + Stripe checkout → webhook → tạo enrollment
   - Quiz generation + scoring
   - Revenue distribution (DistributeRevenueService)
   - B2B license purchase + assignment
4. Thêm RSpec vào CI/CD pipeline

---

### C2. Production SSL Bị Comment

**Mức độ:** Bảo mật
**Effort:** Thấp

```ruby
# config/environments/production.rb (đang bị comment)
# config.force_ssl = true
```

**Hành động:**
1. Bỏ comment `config.force_ssl = true`
2. Kiểm tra `config.cache_classes = true`
3. Thêm `config.assume_ssl = true` nếu deploy sau proxy

---

### C3. Rate Limiting: Không Có

**Mức độ:** Bảo mật (DoS vulnerability)
**Effort:** Trung bình

Không có gem `rack-attack` hoặc tương đương. Endpoint `/create-checkout-session`, `/webhooks`, login có thể bị brute-force.

**Hành động:**
1. Thêm `gem "rack-attack"` vào Gemfile
2. Cấu hình trong `config/initializers/rack_attack.rb`:
   - Giới hạn login: 5 attempts/5 phút/IP
   - Giới hạn checkout: 10 attempts/1 phút/IP
   - Giới hạn API/webhook: 100 requests/phút
3. Thêm throttling cho public endpoints
4. Block suspicious IPs tự động

---

### C4. N+1 Query Problems

**Mức độ:** Performance
**Effort:** Trung bình

Nhiều controller/view không eager load associations:

```
Ví dụ trong enrollments_controller.rb:
  @enrollments = Enrollment.where(user_id: current_user.id)
  → Cần: .includes(:course, :course => :category)

Ví dụ trong courses/index.html.erb:
  @courses.each { |c| c.category } → N+1

Ví dụ trong reviews:
  course.reviews chạy N+1 cho user + instructor
```

**Hành động:**
1. Thêm `gem "bullet"` vào development
2. Duyệt tất cả controllers, thêm `.includes()` cho associations được gọi trong views
3. Checklist cần fix:
   - `CoursesController#index` — includes: [:category, :instructor, :reviews]
   - `EnrollmentsController` — includes: [:course, :course => [:category, :instructor]]
   - `ReviewsController` — includes: [:user, :course]
   - `DiscussionMessagesController` — includes: [:user, :replies => [:user], :reactions]
   - `Instructor::CoursesController#students` — includes: [:enrollments => [:user]]
   - `Admin::RevenuesController` — include associations cho groupdate

---

### C5. MySQL RAND() Trong Quiz Generation

**Mức độ:** Chất lượng
**Effort:** Thấp

```ruby
# app/services/quiz_generator_service.rb
.order("RAND()")  # KHÔNG tốt cho production
```

`RAND()` trong MySQL scan toàn bộ bảng, không dùng được index. Với 1000+ questions, performance rất chậm.

**Hành động:**
1. Thay bằng `ORDER BY RAND()` với LIMIT nhỏ (dưới 1000 rows)
2. Hoặc tốt hơn: dùng `SAMPLE` của MySQL 8+: `ORDER BY id LIMIT X USING INDEX idx_id`
3. Hoặc tốt nhất: dùng Ruby `Array#sample` sau khi fetch IDs
   ```ruby
   question_ids = Question.where(...).pluck(:id)
   selected_ids = question_ids.sample(limit)
   Question.where(id: selected_ids)
   ```

---

### C6. Email Templates Không Có Tiếng Việt

**Mức độ:** UX/Professional
**Effort:** Trung bình

Chỉ có `NotificationMailer` với template text đơn giản. Các email Devise (confirmation, password reset) chỉ có tiếng Anh mặc định.

**Hành động:**
1. Tạo HTML email templates cho:
   - Xác nhận email (Devise `:confirmable`)
   - Reset password
   - Thanh toán thành công
   - Enrollment mới
   - Course được duyệt/từ chối
   - Payout approved/rejected
   - License assigned cho employee
2. Translate sang tiếng Việt
3. Thêm logo và styling nhất quán với brand
4. Sử dụng `letter_opener` trong dev, `sendgrid`/`postmark` trong production

---

### C7. Webhook Payload Load Toàn Bộ Vào Memory

**Mức độ:** Performance/Stability
**Effort:** Thấp

```ruby
# app/controllers/webhooks_controller.rb
payload = request.body.read  # Đọc full payload vào memory
```

Stripe webhook có thể gửi payload rất lớn (100KB+).

**Hành động:**
1. Stream body thay vì đọc full:
   ```ruby
   payload = request.body.read
   # Hoặc dùng: request.body.read(1024) cho small reads
   ```
2. Thêm request size limit ở nginx/apache level

---

## III. Nâng Cấp Kiến Trúc Kỹ Thuật (Technical Debt)

### T1. Thêm Background Jobs (ActiveJob + Sidekiq)

**Effort:** Cao
**Impact:** Cao

Hiện tại dùng `deliver_later` nhưng không có queue backend. Stripe webhook, email, notification đều chạy synchronous.

**Hành động:**
1. Thêm `gem "sidekiq"`, `gem "sinatra"` (for Sidekiq web UI) vào Gemfile
2. Thêm Redis vào infrastructure (docker-compose)
3. Tạo `config/sidekiq.yml`:
   ```yaml
   :concurrency: 5
   :queues:
     - critical  # Stripe webhooks
     - default   # Emails, notifications
     - low       # Analytics, cleanup
   ```
4. Chuyển các jobs sang async:
   - `DistributeRevenueJob`
   - `SendNotificationJob`
   - `EnrollmentConfirmationJob`
   - `CertificateGenerationJob`
   - `CouponExpirationReminderJob`

---

### T2. Thêm Redis Cache Layer

**Effort:** Trung bình
**Impact:** Cao

Không có caching. Mỗi request đều query database.

**Hành động:**
1. Thêm Redis vào docker-compose
2. Cấu hình `config/environments/production.rb`:
   ```ruby
   config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
   ```
3. Cache strategies:
   - Course listings: `Rails.cache.fetch("courses:page:#{page}")`
   - Category with courses: `Rails.cache.fetch("category:#{id}")`
   - Instructor analytics: cache 15 phút
   - Admin stats: cache 5 phút
4. Dùng `cache_names` hoặc `touch: true` để auto-expire khi data thay đổi

---

### T3. API REST (JSON)

**Effort:** Cao
**Impact:** Cao (mở rộng ecosystem)

Hiện tại không có API thực sự. Mobile app, third-party integrations không thể kết nối.

**Hành động:**
1. Tạo API namespace:
   ```
   namespace :api, path: "/api/v1", defaults: { format: :json } do
     resources :courses, only: [:index, :show]
     resources :enrollments, only: [:create, :index]
     resources :lessons, only: [:show]
     resources :quiz_attempts, only: [:create, :show]
     # ...etc
   end
   ```
2. Thêm `gem "jwt"` hoặc `gem "doorkeeper"` cho API authentication
3. API versioning strategy
4. API documentation (OpenAPI/Swagger)
5. Rate limiting riêng cho API

---

### T4. Cải Thiện Internationalization (i18n)

**Effort:** Trung bình
**Impact:** Trung bình

- Chỉ có 2 locales (vi, en) nhưng `en.yml` gần như trống
- Nhiều view vẫn hard-code tiếng Việt
- Email templates chưa translate

**Hành động:**
1. Hoàn thiện `config/locales/en.yml`:
   - Translate toàn bộ admin views
   - Translate flash messages
   - Translate email templates
2. Tạo locale switcher UI trong navbar
3. Dùng `I18n.t("shared.buttons.submit")` thay vì hard-code
4. Thêm `config.i18n.fallbacks = true` cho missing translations
5. Cấu hình `config.i18n.default_locale = :vi` (thay vì :en)

---

### T5. Nâng Cấp Cấu Hình Production

**Effort:** Trung bình
**Impact:** Trung bình

**Hành động:**
1. Uncomment và cấu hình SSL:
   ```ruby
   # config/environments/production.rb
   config.force_ssl = true
   config.assume_ssl = true
   ```
2. Cấu hình CDN cho assets:
   ```ruby
   config.action_controller.asset_host = ENV["CDN_HOST"]
   ```
3. Thêm `config.active_storage.replace_on_assign_to_many = true`
4. Cấu hình `config.active_record.dump_schemas = :schema`
5. Thêm `config.log_tags = [:request_id, :remote_ip]`
6. Cấu hình `config.action_mailer.deliver_later_queue_name = :critical`

---

### T6. RuboCop Nâng Cao

**Effort:** Thấp
**Impact:** Thấp

**Hành động:**
1. Thêm cops bổ sung:
   ```ruby
   require:
     - rubocop-rails
     - rubocop-performance
     - rubocop-rspec
   ```
2. Cấu hình `.rubocop.yml` với target Ruby 3.2
3. Auto-correct safe offenses: `rubocop -A`
4. Thêm vào pre-commit hook

---

## IV. Nâng Cấp UI/UX

### U1. Dark Mode

**Effort:** Trung bình
**Impact:** Cao

Người dùng ngày càng expect dark mode. Nhiều competitor có sẵn.

**Hành động:**
1. Chuyển SCSS sang CSS Custom Properties (variables):
   ```scss
   :root {
     --color-primary: #2563eb;
     --color-bg: #ffffff;
     --color-text: #0f172a;
   }
   [data-theme="dark"] {
     --color-primary: #3b82f6;
     --color-bg: #0f172a;
     --color-text: #f1f5f9;
   }
   ```
2. Override Bootstrap variables trong dark mode
3. Tạo `DarkModeController` (Stimulus) để toggle
4. Lưu preference vào `localStorage`
5. Thêm toggle button vào navbar

---

### U2. PWA (Progressive Web App)

**Effort:** Cao
**Impact:** Cao

Cho phép cài đặt app trên desktop/mobile, offline reading.

**Hành động:**
1. Tạo `app/assets/images/icon-*.png` (multiple sizes)
2. Tạo `app/views/layouts/_pwa_meta_tags.html.erb`:
   ```html
   <link rel="manifest" href="/manifest.json">
   <meta name="apple-mobile-web-app-capable" content="yes">
   ```
3. Tạo `public/manifest.json`:
   ```json
   {
     "name": "E-Learning App",
     "short_name": "Learn",
     "icons": [...],
     "start_url": "/",
     "display": "standalone"
   }
   ```
4. Tạo `app/javascript/serviceworker.js`:
   - Cache course images
   - Cache static assets
   - Offline fallback page
5. Register SW in `application.js`

---

### U3. Responsive Audit & Fix

**Effort:** Cao
**Impact:** Cao

Chưa có mobile testing. Một số pages có thể break trên mobile.

**Hành động:**
1. Dùng BrowserStack hoặc Chrome DevTools mobile emulation
2. Test critical flows trên mobile:
   - Course enrollment
   - Quiz taking
   - Video playback
   - Checkout
3. Fix priority list:
   - Navbar (hamburger menu)
   - Course card grid (1 col mobile)
   - Lesson player (full-width video)
   - Quiz form (zoom input)
   - Admin tables (horizontal scroll)
4. Thêm CSS `overflow-x: auto` cho wide tables
5. Test touch targets (min 44x44px)

---

### U4. Instructor Analytics Dashboard (Nâng cấp)

**Effort:** Trung bình
**Impact:** Cao

Hiện tại instructor revenue page chỉ có chart cơ bản. Cần bổ sung.

**Hành động:**
1. **Revenue KPIs** (trang revenue/index):
   - Tổng doanh thu (all time, tháng này, tuần này)
   - So sánh với tháng trước (% change)
   - Best-selling course
   - Pending payouts
2. **Student Analytics** (trang courses/students):
   - Enrollment trend chart (theo tuần)
   - Completion rate pie chart
   - Average quiz score histogram
   - Student list với search/pagination
3. **Course Performance** (trang courses/index):
   - Rating distribution
   - Enrollment vs. completion scatter
   - Revenue per course bar chart
4. **Coupon Analytics** (trang coupons):
   - Usage count + conversion rate
   - Revenue generated per coupon
   - Top performing coupons
5. Thêm Chartkick + Groupdate cho charts

---

### U5. Admin Analytics Dashboard (Nâng cấp)

**Effort:** Trung bình
**Impact:** Cao

**Hành động:**
1. **Platform KPIs Dashboard** (admin/dashboard):
   - GMV (Gross Merchandise Value) theo ngày/tuần/tháng
   - MAU (Monthly Active Users)
   - New enrollments trend
   - Platform profit (30% platform fee)
2. **User Growth Chart**:
   - New users per week
   - Breakdown by role
   - Churn rate estimation
3. **Content Moderation Queue**:
   - Pending course reviews
   - Flagged reviews
   - Flagged comments
4. **Revenue Breakdown**:
   - By category
   - By instructor
   - Top courses by revenue

---

### U6. Checkout Flow Cải Tiến

**Effort:** Trung bình
**Impact:** Cao

**Hành động:**
1. Tạo trang `checkout-success` (route có, view chưa có):
   - Xác nhận thanh toán
   - Hướng dẫn bắt đầu học
   - Suggest related courses
2. Thêm "Buy as Gift" option:
   - Input recipient email
   - Custom message
   - Send gift notification email
3. Thanh toán bằng Wallet balance:
   - Kiểm tra `current_user.wallet.balance`
   - Cho phép thanh toán 1 phần bằng wallet, phần còn lại bằng card
4. Payment retry flow cho failed payments

---

### U7. Course Detail Page Enhancement

**Effort:** Thấp
**Impact:** Trung bình

**Hành động:**
1. Thêm "Preview Curriculum" section (guest có thể thấy outline, không thấy content)
2. Thêm "Last Updated" timestamp
3. Thêm "Requirements" và "What you'll learn" sections
4. Thêm instructor card với:
   - Total students
   - Total courses
   - Average rating
   - Bio snippet
5. Sticky enroll button khi scroll

---

### U8. Notification Center Đầy Đủ

**Effort:** Trung bình
**Impact:** Trung bình

Hiện tại có model + dropdown partial, nhưng chưa có full page.

**Hành động:**
1. Tạo `notifications/index.html.erb`:
   - List tất cả notifications
   - Filter: All / Unread / Type
   - Mark all as read
   - Pagination
2. Thêm types:
   - `enrollment` — khi được enroll
   - `course_approved` / `course_rejected`
   - `review_received`
   - `payout_status`
   - `license_assigned` (B2B)
   - `quiz_completed`
   - `certificate_earned`
3. Real-time updates via Turbo Streams

---

## V. B2B Module Nâng Cấp (Enterprise)

### B1. Enterprise Dashboard

**Effort:** Cao
**Impact:** Cao

**Hành động:**
1. **Employee Progress Report** (business/dashboard nâng cấp):
   - Table: Employee name, Enrolled courses, Completed, In Progress, Completion %
   - Search & filter by employee, course
   - Export CSV
2. **Training ROI Dashboard**:
   - Total licenses purchased
   - Total training spend
   - Completion rate
   - Average quiz scores
3. **Course Performance** (trong Business):
   - Most assigned courses
   - Least assigned courses
4. **License Utilization**:
   - Total licenses vs. assigned
   - Expiring soon alerts
5. Thêm `Gem "groupdate"` cho time-based charts

---

### B2. Bulk CSV Import Employees

**Effort:** Trung bình
**Impact:** Cao

**Hành động:**
1. Tạo `business/employees/import` action:
   ```ruby
   # Template CSV:
   # email,name,phone,department
   # user@example.com,Nguyen Van A,0901234567,Engineering
   ```
2. Validate columns và format
3. Batch insert users
4. Error report: which rows failed và why
5. Preview before import

---

### B3. License Expiration Tracking

**Effort:** Thấp
**Impact:** Trung bình

**Hành động:**
1. Thêm `expires_at` column vào `licenses` table:
   ```bash
   rails g migration AddExpiresAtToLicenses expires_at:datetime
   ```
2. Cập nhật `License` model:
   ```ruby
   enum status: { available: 0, assigned: 1, expired: 2 }

   scope :expiring_soon, -> { where("expires_at BETWEEN ? AND ?", Time.now, 7.days.from_now) }
   ```
3. Thêm alert trong Business dashboard:
   - "3 licenses expiring within 7 days"
   - Link đến renewal flow
4. Job hàng ngày auto-expire licenses:
   ```ruby
   License.where("expires_at < ?", Time.now).where(status: :assigned).update_all(status: :expired)
   ```

---

### B4. Custom Learning Path Cho Tổ Chức

**Effort:** Rất cao
**Impact:** Trung bình

**Hành động:**
1. Tạo `OrganizationLearningPath` model:
   ```ruby
   OrganizationLearningPath
     organization_id
     title
     description
     course_ids (serialized array)
   end
   ```
2. OrganizationLearningPathAssignment:
   ```ruby
     organization_learning_path_id
     user_id (employee)
     progress_percentage
     started_at
     completed_at
   end
   ```
3. UI trong Business portal:
   - Tạo/cấu hình learning path
   - Assign path cho employee(s)
   - Theo dõi progress

---

### B5. Organization Settings & Branding

**Effort:** Cao
**Impact:** Trung bình

**Hành động:**
1. Thêm `OrganizationSettings` model:
   ```ruby
     organization_id
     primary_color
     logo_url
     custom_domain
   end
   ```
2. Middleware để detect custom domain:
   ```ruby
   # config/application.rb
   config.middleware.use OrganizationResolver
   ```
3. Override CSS variables khi truy cập qua custom domain:
   ```ruby
   before_action :set_organization_theme
   ```

---

## VI. Instructor Module Nâng Cấp

### I1. Course Builder Drag-Drop UI

**Effort:** Cao
**Impact:** Cao

Hiện tại instructor tạo course qua form cơ bản. Cần drag-drop builder.

**Hành động:**
1. Tạo `Instructor::CourseBuilderController`:
   - Sort modules (AJAX reordering)
   - Sort lessons within modules
   - Inline add/edit/delete
2. JavaScript:
   - `SortableJS` library cho drag-drop
   - Optimistic UI updates (Turbo)
3. Course outline tree view:
   ```
   📁 Module 1: Ruby Basics
     ├─ 📄 Lesson 1.1: Variables
     ├─ 📄 Lesson 1.2: Methods
     └─ 📝 Quiz 1
   📁 Module 2: Rails
     └─ ...
   ```

---

### I2. Instructor Public Profile Page

**Effort:** Trung bình
**Impact:** Trung bình

**Hành động:**
1. Tạo `public_instructors/:id` route:
   ```ruby
   get "instructors/:id", to: "public_instructors#show", as: :public_instructor
   ```
2. `PublicInstructorsController`:
   ```ruby
   def show
     @instructor = User.instructor.find(params[:id])
     @courses = @instructor.courses.published
     @stats = {
       total_students: @courses.sum(&:enrollments_count),
       avg_rating: @courses.average(:average_rating),
       total_courses: @courses.count
     }
   end
   ```
3. View `public_instructors/show.html.erb`:
   - Avatar, name, bio
   - Stats cards
   - Course listing
   - Reviews about instructor's courses

---

### I3. Instructor Earnings & Tax

**Effort:** Trung bình
**Impact:** Trung bình

**Hành động:**
1. Thêm tax information fields vào `InstructorProfile`:
   ```ruby
   add_column :instructor_profiles, :tax_id, :string
   add_column :instructor_profiles, :tax_country, :string
   ```
2. Earnings breakdown trong revenues:
   - Gross revenue
   - Platform fee (30%)
   - Tax withheld (nếu có)
   - Net payout
3. Export earnings report (PDF/CSV)

---

## VII. AI Features (Phase 0 - Thesis Core)

### A1. AI Study Assistant Integration

**Effort:** Rất cao
**Impact:** Rất cao
**Ưu tiên:** CAO NHẤT (Thesis Core)

**Hành động:**
1. Thêm `gem "ruby-openai"` hoặc `gem "google-apis-gemini"` vào Gemfile
2. Tạo `AiConversation` model:
   ```ruby
   AiConversation
     user_id
     lesson_id
     course_id
     messages_count
   end
   ```
3. Tạo `AiMessage` model:
   ```ruby
   AiMessage
     ai_conversation_id
     role (user/assistant)
     content
     tokens_used
   end
   ```
4. `AiConversationsController`:
   - Context injection: current lesson title, course title, user's progress
   - System prompt với domain knowledge
   - Streaming responses via Turbo Streams
5. View `lessons/tabs/_ai_assistant.html.erb`:
   - Chat interface trong lesson tabs
   - Suggested questions
   - Conversation history

---

### A2. AI Course Recommendation

**Effort:** Cao
**Impact:** Cao
**Ưu tiên:** CAO NHẤT

**Hành động:**
1. Tạo `CourseRecommendationService`:
   ```ruby
   # Logic:
   # 1. Collaborative filtering: users who enrolled X also enrolled Y
   # 2. Content-based: same category + higher level
   # 3. Quiz-based: weak topics → recommend remedial courses
   # 4. Wishlist-based: similar to saved courses
   ```
2. Tạo `RecommendationsController`:
   - `/api/recommendations` (JSON)
   - Cached với user behavior
3. Placement:
   - Homepage: "Vì bạn đã học..."
   - Course detail: "Học viên cũng mua..."
   - Post-enrollment: "Tiếp theo bạn nên học..."

---

### A3. Adaptive Quiz Engine

**Effort:** Trung bình
**Impact:** Cao
**Ưu tiên:** CAO NHẤT

**Hành động:**
1. Tạo `UserSkillProfile` model:
   ```ruby
   UserSkillProfile
     user_id
     course_id
     topic
     mastery_level (0-100)
     quiz_attempts_count
     avg_response_time
   end
   ```
2. Thêm logic trong `QuizScoringService`:
   ```ruby
   # Sau mỗi quiz:
   # 1. Tính mastery thay đổi
   # 2. Update UserSkillProfile
   # 3. Adjust difficulty cho quiz tiếp theo
   ```
3. Modify `QuizGeneratorService`:
   - Auto-adjust difficulty ratio dựa trên user's skill
   - Correct streak → increase hard ratio
   - Many wrong → increase easy ratio

---

### A4. Personal Learning Dashboard

**Effort:** Cao
**Impact:** Cao
**Ưu tiên:** CAO NHẐT

**Hành động:**
1. Tạo `LearningActivity` model:
   ```ruby
   LearningActivity
     user_id
     course_id
     activity_type (video, quiz, note, discussion)
     duration_seconds
     completed_at
   end
   ```
2. Tạo `LearningGoal` model:
   ```ruby
   LearningGoal
     user_id
     goal_type (lessons_per_week, hours_per_week)
     target_value
     current_value
     week_start
   end
   ```
3. Dashboard `my_learning/index.html.erb`:
   - Weekly learning time chart
   - Learning streak counter
   - Current week's goal progress
   - Strength/weakness breakdown (từ quiz results)
   - Recommended next actions

---

### A5. AI Summary & Flashcards

**Effort:** Cao
**Impact:** Trung bình
**Ưu tiên:** TRUNG BÌNH

**Hành động:**
1. Tạo `LessonSummary` model:
   ```ruby
   LessonSummary
     lesson_id
     summary_text
     key_takeaways (JSON array)
     flashcards (JSON array)
     generated_at
   end
   ```
2. Service gọi OpenAI/Gemini API:
   ```ruby
   # Prompt:
   # "Summarize this lesson content in 3-5 bullet points.
   # Extract 5 key takeaways.
   # Generate 5 flashcards (Q&A format)."
   ```
3. Button "AI Summary" trong lesson page:
   - Show loading state
   - Display summary + flashcards
   - Option to copy/save
4. Spaced repetition storage:
   ```ruby
   FlashcardReview
     lesson_summary_id
     user_id
     ease_factor
     interval_days
     next_review_date
   end
   ```

---

## VIII. Security Hardening

### S1. Two-Factor Authentication (2FA)

**Effort:** Trung bình
**Impact:** Cao

**Hành động:**
1. Thêm Devise OTP:
   ```ruby
   gem "devise-two-factor"
   gem "rotp"
   ```
2. User settings: enable 2FA
3. QR code setup flow
4. Recovery codes

---

### S2. Audit Log

**Effort:** Trung bình
**Impact:** Trung bình

**Hành động:**
1. Tạo `AuditLog` model:
   ```ruby
   AuditLog
     user_id
     action (create, update, delete)
     auditable_type
     auditable_id
     changes (JSON)
     ip_address
     user_agent
   end
   ```
2. Concern để include vào models:
   ```ruby
   module Auditable
     extend ActiveSupport::Concern
   end
   ```
3. Track important actions:
   - Role changes
   - Course status changes
   - Payout approvals
   - Coupon creation/deletion
   - Organization changes

---

### S3. Content Security Policy

**Effort:** Thấp
**Impact:** Trung bình

**Hành động:**
1. Cấu hình CSP trong `config/initializers/content_security_policy.rb`:
   ```ruby
   policy.default_src :self, :https
   policy.font_src :self, :https, :data
   policy.img_src :self, :https, :data, :blob
   policy.script_src :self, :https
   policy.style_src :self, :https, :unsafe_inline
   ```
2. Thêm nonce cho inline scripts cần thiết
3. Report-uri cho violations

---

### S4. Video Watermarking (Anti-Piracy)

**Effort:** Cao
**Impact:** Trung bình

**Hành động:**
1. Dynamic watermarking:
   - Overlay user name + email lên video
   - Thực hiện ở CDN/streaming layer
2. Hoặc server-side:
   - FFmpeg với drawtext filter
   - Batch process uploaded videos
3. Disable right-click (client-side, không an toàn tuyệt đối)

---

## IX. DevOps & Monitoring

### D1. Error Tracking (Sentry)

**Effort:** Thấp
**Impact:** Cao

**Hành động:**
1. Thêm `gem "sentry-ruby"`, `gem "sentry-rails"`
2. Cấu hình:
   ```ruby
   Sentry.init do |config|
     config.dsn = ENV["SENTRY_DSN"]
     config.breadcrumbs_logger = [:active_support_logger]
     config.traces_sample_rate = 0.1
   end
   ```
3. Ignore certain errors:
   ```ruby
   config.excluded_exceptions += ["ActiveRecord::RecordNotFound"]
   ```

---

### D2. Performance Monitoring (Skylight)

**Effort:** Thấp
**Impact:** Trung bình

**Hành động:**
1. Thêm `gem "skylight"`
2. Setup vào CI
3. Review slow requests regularly

---

### D3. CI/CD Pipeline Nâng Cấp

**Effort:** Trung bình
**Impact:** Cao

**Hành động:**
1. Nâng cấp `.github/workflows/`:
   ```yaml
   jobs:
     lint:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - run: bundle exec rubocop

     test:
       runs-on: ubuntu-latest
       services:
         mysql:
           image: mysql:8.0
         redis:
           image: redis:7
       steps:
         - run: bundle exec rspec
         - run: bundle exec brakeman --no-pager

     security:
       runs-on: ubuntu-latest
       steps:
         - run: bundle exec bundle audit
         - run: npm audit  # if JS dependencies

     deploy:
       needs: [lint, test]
       if: github.ref == 'refs/heads/main'
   ```

---

## X. Accessibility (A11y)

### A11y1. WCAG 2.1 AA Audit

**Effort:** Cao
**Impact:** Trung bình

**Hành động:**
1. Chạy `axe-core` audit:
   ```bash
   npx @axe-core/cli http://localhost:3000
   ```
2. Fix critical issues:
   - Color contrast (4.5:1 minimum)
   - Missing alt texts
   - Missing form labels
   - Missing ARIA landmarks
3. Keyboard navigation:
   - Tab order
   - Focus indicators
   - Skip links
4. Screen reader testing (VoiceOver, NVDA)

---

### A11y2. Semantic HTML

**Effort:** Trung bình
**Impact:** Thấp

**Hành động:**
1. Replace generic `<div>` với semantic tags:
   ```html
   <nav> instead of <div class="nav">
   <main> instead of <div class="content">
   <aside> instead of <div class="sidebar">
   <header> instead of <div class="header">
   ```
2. Heading hierarchy (h1 → h2 → h3)
3. `<button>` vs `<a>` distinction

---

## XI. Ma Trận Ưu Tiên Tổng Hợp

### Priority Matrix (Effort vs Impact)

```
                    Low Effort          High Effort
              ┌─────────────────┬─────────────────┐
   High       │ C2. SSL          │ C1. Tests       │
   Impact     │ C3. Rate Limit   │ T1. Sidekiq     │
              │ C4. N+1 Fix      │ T2. Redis       │
              │ C6. Email        │ T3. REST API    │
              │ U4. Instructor   │ U1. Dark Mode   │
              │    Analytics     │ U2. PWA         │
              │ U5. Admin        │ B1. Enterprise  │
              │    Analytics     │    Dashboard    │
              │ S1. CSP          │ A1. AI Study    │
              │                 │    Assistant    │
              ├─────────────────┼─────────────────┤
   Low        │ C5. RAND() fix   │ U3. Responsive  │
   Impact     │ C7. Webhook      │ A11y1. A11y    │
              │    Memory        │    Audit       │
              │ T4. i18n         │ U7. Course      │
              │    Completion    │    Detail       │
              │ T5. Production   │    Enhancement │
              │    Config        │ S2. Audit Log   │
              │ U6. Checkout     │ S4. Video       │
              │    Flow          │    Watermark   │
              │ U8. Notifications│ A11y2. Semantic │
              │ B3. License      │    HTML        │
              │    Expiration    │                 │
              │ I2. Instructor    │                 │
              │    Profile       │                 │
              └─────────────────┴─────────────────┘
```

### Thứ Tự Triển Khai Đề Xuất

```
GIAI ĐOẠN 1: Security & Stability (Tuần 1-2)
═══════════════════════════════════════════════
[C] C2. Production SSL          ☐ 0.5 ngày
[C] C3. Rate Limiting          ☐ 1 ngày
[C] C6. Email Templates         ☐ 2 ngày
[T] T5. Production Config       ☐ 0.5 ngày
[C] C4. N+1 Queries Fix        ☐ 2 ngày
[D] D1. Sentry Setup           ☐ 0.5 ngày
[C] C5. MySQL RAND() fix       ☐ 0.5 ngày

GIAI ĐOẠN 2: UI/UX Cải Tiến (Tuần 3-5)
═══════════════════════════════════════════════
[U] U8. Notification Center     ☐ 2 ngày
[U] U6. Checkout Flow           ☐ 2 ngày
[U] U4. Instructor Analytics   ☐ 3 ngày
[U] U5. Admin Analytics        ☐ 3 ngày
[U] U7. Course Detail Enhance  ☐ 1 ngày

GIAI ĐOẠN 3: B2B Module (Tuần 6-8)
═══════════════════════════════════════════════
[B] B3. License Expiration      ☐ 1 ngày
[B] B2. Bulk CSV Import         ☐ 2 ngày
[B] B1. Enterprise Dashboard   ☐ 4 ngày
[I] I1. Course Builder UI       ☐ 5 ngày
[I] I2. Instructor Profile      ☐ 2 ngày
[B] B4. Custom Learning Path   ☐ 5 ngày (optional)

GIAI ĐOẠN 4: AI Features (Thesis) (Tuần 9-14)
═══════════════════════════════════════════════
[A] A3. Adaptive Quiz           ☐ 3 ngày
[A] A2. Course Recommendation   ☐ 5 ngày
[A] A1. AI Study Assistant     ☐ 8 ngày
[A] A4. Learning Dashboard     ☐ 5 ngày
[A] A5. AI Summary/Flashcards  ☐ 4 ngày

GIAI ĐOẠN 5: Kiến Trúc (Tuần 15-18)
═══════════════════════════════════════════════
[C] C1. Test Coverage           ☐ 8 ngày
[T] T1. Sidekiq Setup           ☐ 2 ngày
[T] T2. Redis Cache            ☐ 2 ngày
[T] T3. REST API               ☐ 6 ngày
[T] T4. i18n Completion        ☐ 3 ngày

GIAI ĐOẠN 6: Polish & Launch (Tuần 19-20)
═══════════════════════════════════════════════
[U] U1. Dark Mode               ☐ 3 ngày
[U] U2. PWA                     ☐ 4 ngày
[U] U3. Responsive Audit       ☐ 3 ngày
[S] S1. 2FA                    ☐ 2 ngày
[S] S2. Audit Log              ☐ 2 ngày
[D] D3. CI/CD Upgrade           ☐ 2 ngày
[A11y] A11y1 + A11y2           ☐ 4 ngày
```

---

## XII. Checklist Before Any Feature

Mọi feature mới cần đảm bảo:

- [ ] **Tests** — Unit tests + integration tests
- [ ] **N+1 check** — Dùng Bullet verify không có N+1
- [ ] **i18n** — Dùng `I18n.t()` thay vì hard-code
- [ ] **Responsive** — Test trên mobile
- [ ] **Accessibility** — Keyboard navigation + screen reader
- [ ] **Security** — Authorization check (CanCanCan)
- [ ] **Performance** — Query count < 20 per request
- [ ] **RuboCop** — `bundle exec rubocop -a` trước commit
- [ ] **Schema** — Migration có rollback plan
- [ ] **Logging** — Có log cho debugging

---

## XIII. Open Questions (Cần Thảo Luận)

1. **AI Provider** — OpenAI (GPT-4) vs Google Gemini vs self-hosted? Chi phí + latency?
2. **Mobile Strategy** — PWA đủ hay cần native app (React Native/Flutter)?
3. **Subscription Pricing** — Plan đã có nhưng chưa rõ gate content thế nào (Pro vs Premium vs Free)?
4. **Video Hosting** — Hiện dùng video URL external. Có cần self-hosted (Mux, Cloudflare Stream)?
5. **Search** — Ransack đủ cho hiện tại hay cần Elasticsearch?
6. **Scale Expectation** — 100 users hay 10,000 users? Ảnh hưởng đến Redis, Sidekiq sizing.
7. **Deployment Target** — VPS self-host, Railway, Render, AWS, GCP?
8. **Certificate Format** — PDF là đủ hay cần blockchain verification?

---

## XIV. Out of Scope (Không Trong Kế Hoạch Này)

- Multi-tenancy database (đang dùng Organization là app-level tenant)
- GraphQL API (REST đủ cho nhu cầu hiện tại)
- Real-time video streaming (WebRTC)
- White-label subdomain setup (B5 có trong list nhưng optional)
- Mobile native app (PWA đủ cho MVP)

---

## XV. Success Metrics

| Metric | Current | Target (6 tháng) |
|--------|---------|------------------|
| Test coverage | 0% | 60% |
| Page load time | ~2s | <1s |
| Mobile traffic | Unknown | 40% |
| Course completion rate | Unknown | +20% |
| Revenue (MRR) | Unknown | +50% |
| Instructor satisfaction | Unknown | NPS > 50 |
| Support tickets | Unknown | -30% |

---

*Kế hoạch này sẽ được cập nhật sau khi thảo luận và duyệt từng phần.*
