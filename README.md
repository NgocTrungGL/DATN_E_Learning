# E-Learning System

Nền tảng học trực tuyến viết bằng Ruby on Rails, hỗ trợ bán khóa học B2C, đào tạo doanh nghiệp B2B, quản trị nội dung, giảng viên, lộ trình học cá nhân hóa, gợi ý khóa học, thanh toán Stripe, chứng chỉ, ví doanh thu và dashboard phân tích.

Dự án này được xây dựng theo mô hình monolith Rails 7, dùng PostgreSQL làm cơ sở dữ liệu chính, Redis cho Action Cable/cache/job backend khi triển khai, Devise cho xác thực, CanCanCan cho phân quyền, Stripe cho thanh toán, Cloudinary cho lưu trữ media và các service nội bộ cho recommendation/personalized learning.

## Mục Lục

- [Tổng quan nghiệp vụ](#tổng-quan-nghiệp-vụ)
- [Tính năng chính](#tính-năng-chính)
- [Vai trò người dùng](#vai-trò-người-dùng)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Kiến trúc thư mục](#kiến-trúc-thư-mục)
- [Mô hình dữ liệu](#mô-hình-dữ-liệu)
- [Luồng xử lý quan trọng](#luồng-xử-lý-quan-trọng)
- [API](#api)
- [Yêu cầu môi trường](#yêu-cầu-môi-trường)
- [Cài đặt local](#cài-đặt-local)
- [Chạy bằng Docker](#chạy-bằng-docker)
- [Seed dữ liệu](#seed-dữ-liệu)
- [Biến môi trường](#biến-môi-trường)
- [Lệnh phát triển thường dùng](#lệnh-phát-triển-thường-dùng)
- [Test](#test)
- [Background jobs và Rake tasks](#background-jobs-và-rake-tasks)
- [Triển khai](#triển-khai)
- [Ghi chú vận hành](#ghi-chú-vận-hành)

## Tổng Quan Nghiệp Vụ

Ứng dụng mô phỏng một marketplace học trực tuyến đầy đủ:

- Học viên có thể duyệt khóa học, thêm wishlist/cart, thanh toán, học bài, làm quiz, ghi chú, bình luận, tham gia thảo luận, theo dõi tiến độ và nhận chứng chỉ.
- Giảng viên có thể đăng ký trở thành instructor, tạo khóa học, module, lesson, quiz, coupon, gửi khóa học chờ duyệt, xem doanh thu, payout, phân tích học viên và hiệu suất khóa học.
- Admin quản trị toàn hệ thống: user, category, course, lesson, quiz, review, comment, coupon, enrollment, revenue, payout, duyệt instructor và duyệt khóa học.
- Doanh nghiệp có thể đăng ký B2B, mua license số lượng lớn, quản lý nhân viên, gán/thu hồi license, import nhân viên hàng loạt và xem báo cáo tiến độ.
- Hệ thống recommendation gợi ý khóa học dựa trên tín hiệu tương tác, độ phổ biến, collaborative filtering, content filtering và embedding AI.
- Hệ thống personalized learning tạo study plan, tự điều chỉnh lịch học, nhắc học, phát hiện rủi ro học tập và đề xuất focus items.

## Tính Năng Chính

### Học viên

- Đăng ký, đăng nhập, xác nhận email, quản lý hồ sơ cá nhân.
- Duyệt danh mục, tìm kiếm/lọc khóa học, xem chi tiết khóa học.
- Wishlist, cart, áp dụng coupon và checkout qua Stripe.
- Truy cập bài học theo enrollment, license hoặc subscription tier.
- Theo dõi tiến độ bài học/video, tự động hoàn thành bài học.
- Làm quiz, lưu câu trả lời, hoàn thành bài kiểm tra, xem review khi đạt điều kiện.
- Ghi chú cá nhân theo lesson.
- Bình luận lesson và quản lý comment của chính mình.
- Viết review cho khóa học.
- Thảo luận dạng forum và chat trong từng khóa học.
- Nhận notification.
- Xem chứng chỉ và in chứng chỉ theo certificate code.
- Dashboard học tập cá nhân, learning goals, study plans và study plan items.

### Giảng viên

- Đăng ký hồ sơ instructor và chờ admin duyệt.
- Dashboard giảng viên.
- Quản lý khóa học của chính mình.
- Tạo/sửa module, lesson, quiz, question, quiz-question mapping.
- Kéo thả/sắp xếp module và lesson trong course builder.
- Submit khóa học để admin review.
- Xem danh sách học viên trong khóa học.
- Xem quiz attempts, course performance, student analytics và activity log.
- Tạo coupon.
- Xem doanh thu và gửi yêu cầu payout.
- Theo dõi discussion trong khóa học.

### Admin

- Toàn quyền quản trị qua `admin` namespace.
- Quản lý user, category, course, module, lesson, quiz, question.
- Duyệt hoặc từ chối hồ sơ instructor.
- Duyệt hoặc từ chối khóa học do instructor gửi.
- Quản lý review, comment, enrollment, coupon.
- Xem revenue, payout request.
- Xem recommendation evaluation.
- Xem personalization report và refresh demo data.

### B2B / Business Portal

- Đăng ký tổ chức/doanh nghiệp.
- Company admin quản lý dashboard doanh nghiệp.
- Quản lý employees.
- Import nhân viên hàng loạt và tải template import.
- Mua license khóa học theo số lượng.
- Gán và thu hồi license cho nhân viên.
- Xem hóa đơn.
- Xem báo cáo nhân viên, tiến độ học tập và gợi ý cải thiện.
- Employee truy cập khóa học thông qua license được gán.

### Recommendation và AI Embedding

- Gợi ý khóa học qua `Recommendations::Engine`.
- Fallback sang popularity khi chưa có đủ tín hiệu cá nhân hóa.
- Cache recommendation vào `user_recommendations`.
- Tính similarity giữa khóa học qua `CourseSimilarityJob`.
- Backfill embedding cho khóa học đã publish vào `course_embeddings`.
- Hỗ trợ provider embedding qua `EMBEDDING_PROVIDER`, gồm OpenAI và Gemini theo service hiện có.
- Có endpoint riêng để thử gợi ý bằng AI embedding.
- Có offline evaluator để so sánh hybrid recommender với AI embedding recommender.

### Personalized Learning

- Theo dõi learning activities, streaks và goals.
- Tạo study plan theo course, deadline và thời gian học ưu tiên.
- Tính learning profile dựa trên dữ liệu 30 ngày gần nhất.
- Ước lượng thời lượng lesson/quiz và chia lịch học theo daily capacity.
- Tự điều chỉnh study plan khi có item quá hạn.
- Nhắc lịch học hôm nay, cảnh báo quá hạn và deadline sắp tới.
- Phát hiện rủi ro học tập, đề xuất focus lessons và tối ưu study plan.

## Vai Trò Người Dùng

Model `User` định nghĩa các role:

| Role | Ý nghĩa |
| --- | --- |
| `admin` | Quản trị toàn bộ hệ thống |
| `instructor` | Giảng viên tạo và quản lý khóa học |
| `student` | Học viên cá nhân |
| `company_admin` | Quản trị viên doanh nghiệp |
| `employee` | Nhân viên học qua license doanh nghiệp |

Phân quyền tập trung tại `app/models/ability.rb` bằng CanCanCan.

Một số nguyên tắc phân quyền chính:

- Admin `manage :all`.
- Instructor quản lý course/module/lesson/quiz/question do mình tạo.
- Student có thể học khóa đã enroll, khóa có license, khóa được subscription cho phép hoặc lesson free preview.
- Company admin quản lý tài nguyên thuộc organization của mình.
- Employee học các khóa được gán license.
- Guest chỉ đọc course/category/review/comment và lesson free preview.

## Công Nghệ Sử Dụng

### Backend

- Ruby `3.2.2`
- Rails `~> 7.0.5`
- PostgreSQL qua gem `pg`
- Puma web server
- Redis
- Active Job
- Active Storage
- Action Text/Trix
- Devise
- CanCanCan
- Ransack
- Pagy
- Stripe
- Cloudinary
- Sentry

### Frontend

- Rails ERB/Slim views
- Sprockets asset pipeline
- Sass/SCSS qua `sassc-rails`
- Bootstrap 5
- Importmap
- Turbo Rails
- Stimulus Rails
- Chartkick
- Anime.js

### Dev/Test

- Minitest
- Capybara
- Selenium WebDriver
- RuboCop và RuboCop Rails
- Faker cho development seed/demo

## Kiến Trúc Thư Mục

```text
app/
  controllers/
    admin/                 # Khu vực quản trị hệ thống
    api/v1/                # API JSON
    business/              # Business portal B2B
    b2b/                   # Đăng ký doanh nghiệp
    instructor/            # Dashboard và quản trị của giảng viên
    student/               # Dashboard học viên, goals, study plans
  models/                  # ActiveRecord models và Ability
  services/                # Business logic tách khỏi controller/model
    recommendations/       # Recommendation engine, scorer, evaluator, embedding
    learning/              # Personalization, behavior profile, risk detector
    open_ai/               # OpenAI embedding client
    gemini/                # Gemini embedding client
  jobs/                    # Active Job jobs
  views/                   # ERB/Slim templates
  assets/                  # SCSS, images, JS assets
config/
  routes.rb                # Route chính của toàn ứng dụng
  database.yml             # Cấu hình PostgreSQL local
  database.yml.example     # Mẫu cấu hình DB
  storage.yml              # Disk/Cloudinary Active Storage
  initializers/            # Devise, Stripe, Cloudinary, Sentry, Pagy...
db/
  migrate/                 # Database migrations
  schema.rb                # Schema hiện tại
  seeds.rb                 # Entry seed tổng
  seeds/                   # Seed data chia theo module
lib/
  tasks/                   # Rake tasks learning/recommendations/cloudinary
test/
  services/                # Unit tests hiện có cho services
```

## Mô Hình Dữ Liệu

Schema hiện tại gồm các nhóm bảng lớn:

### Người dùng và phân quyền

- `users`: tài khoản, role, Devise confirmable.
- `profiles`: hồ sơ người dùng.
- `instructor_profiles`: hồ sơ đăng ký giảng viên.
- `organizations`: tổ chức/doanh nghiệp.
- `notifications`: thông báo trong hệ thống.

### Khóa học và nội dung

- `categories`: danh mục cha/con.
- `courses`: khóa học, giá, trạng thái `draft/pending/published/rejected`.
- `course_learning_outcomes`: kết quả học tập mong muốn.
- `course_modules`: module/chương học.
- `lessons`: bài học.
- `quizzes`, `questions`, `question_options`, `quiz_questions`: ngân hàng câu hỏi và quiz.

### Học tập

- `enrollments`: ghi danh khóa học.
- `progress_trackings`: tiến độ lesson/quiz.
- `quiz_attempts`, `quiz_answers`: lượt làm quiz và câu trả lời.
- `notes`: ghi chú cá nhân.
- `certificates`: chứng chỉ hoàn thành khóa học.
- `learning_activities`: hoạt động học tập.
- `learning_streaks`: chuỗi ngày học.
- `learning_goals`: mục tiêu học tập.
- `study_plans`, `study_plan_items`, `study_plan_adjustments`: kế hoạch học và các lần điều chỉnh.

### Thương mại

- `carts`, `cart_items`: giỏ hàng.
- `wishlists`: danh sách yêu thích.
- `coupons`: mã giảm giá global hoặc theo course.
- `subscriptions`: gói truy cập khóa học.
- `wallets`, `wallet_transactions`: ví và giao dịch doanh thu.
- `payout_requests`: yêu cầu rút tiền của giảng viên.

### B2B

- `licenses`: license khóa học doanh nghiệp.
- `invoices`: hóa đơn mua license.

### Tương tác cộng đồng

- `comments`: bình luận lesson.
- `reviews`: đánh giá khóa học.
- `discussion_posts`, `discussion_replies`: forum discussion.
- `discussion_messages`, `message_reactions`: chat/thảo luận nhanh trong khóa học.

### Recommendation

- `course_similarities`: điểm tương đồng giữa khóa học.
- `course_embeddings`: vector embedding của khóa học.
- `user_recommendations`: recommendation cache theo user.

## Luồng Xử Lý Quan Trọng

### Trạng thái khóa học

Course dùng enum:

```ruby
draft: 0
pending: 1
published: 2
rejected: 3
```

Instructor tạo khóa học ở trạng thái nháp, submit để chuyển sang pending. Admin duyệt để publish hoặc reject. Khi status thay đổi sang `published` hoặc `rejected`, model `Course` tạo notification cho creator.

### Quyền truy cập khóa học

User có thể truy cập nội dung course nếu một trong các điều kiện đúng:

- Là admin.
- Là creator của course.
- Có enrollment active.
- Có license assigned.
- Subscription hiện tại cho phép truy cập.
- Lesson là free preview.

Subscription tier trong `User#subscription_allows_course?`:

- `premium`: truy cập tất cả.
- `pro`: truy cập khóa học có giá không quá `1_000_000`.
- `free`: chỉ truy cập khóa miễn phí.

### Checkout Stripe

Các luồng checkout chính:

- Mua một khóa học: `POST /create-checkout-session`
- Checkout cả giỏ hàng: `POST /checkout-cart`
- Webhook Stripe: `POST /webhooks`
- Trang success: `GET /checkout-success`

Checkout hỗ trợ:

- Giá sau coupon global.
- Coupon thủ công lưu trong session.
- Mua license số lượng lớn.
- Giảm 10% khi mua license từ 10 đơn vị trở lên.
- Giới hạn tối thiểu Stripe VND: `15_000`.

### Study Plan

`StudyPlanService` chịu trách nhiệm:

- Validate user/course/request.
- Tạo hoặc kích hoạt lại plan cũ.
- Tính learning profile từ `learning_activities` 30 ngày gần nhất.
- Tính daily capacity.
- Ước lượng thời lượng lesson và quiz.
- Xếp lịch theo preferred study times.
- Auto-adjust khi có overdue items.
- Kiểm tra feasibility deadline.

### Recommendation

`Recommendations::Engine` là entry point cho controller:

1. Đọc recommendation cache còn fresh từ `user_recommendations`.
2. Nếu user có tín hiệu cá nhân hóa, compute và cache lại.
3. Nếu chưa đủ tín hiệu hoặc cache rỗng, enqueue `RecommendationJob`.
4. Trả fallback popularity, loại trừ các course user đã tương tác.

Các tín hiệu tương tác gồm enrollment, wishlist, review, cart item và progress tracking.

## API

API hiện có nằm dưới namespace `/api/v1`.

### Lấy recommendation cá nhân hóa

```http
GET /api/v1/recommendations?limit=10
```

Yêu cầu đăng nhập.

Response mẫu:

```json
{
  "data": [
    {
      "course_id": 1,
      "title": "Ruby on Rails Masterclass",
      "description": "Short description...",
      "thumbnail_url": "https://...",
      "price": "500000.0",
      "category": "Web Development",
      "instructor": "Instructor Name",
      "score": 0.92,
      "reason_type": "hybrid"
    }
  ]
}
```

### Lấy recommendation bằng AI embedding

```http
GET /api/v1/recommendations/ai_embedding?limit=10
```

Yêu cầu đăng nhập.

Response có thêm `meta.algorithm = "ai_embedding"`.

### Lấy subcategories

```http
GET /api/v1/categories/:id/subcategories
```

## Yêu Cầu Môi Trường

- Ruby `3.2.2`
- Bundler
- PostgreSQL 15 hoặc tương thích
- Redis nếu chạy Action Cable/production-like jobs
- Node.js
- Yarn
- Stripe CLI nếu muốn test webhook local
- Tài khoản Cloudinary nếu dùng upload/storage cloud
- API key OpenAI hoặc Gemini nếu dùng AI embedding

## Cài Đặt Local

### 1. Clone source

```bash
git clone <repository-url>
cd dn-ruby-naitei-2025_e-learning-system
```

### 2. Cài Ruby gems và JS packages

```bash
bundle install
yarn install
```

### 3. Cấu hình database

Tạo file `config/database.yml` từ file mẫu:

```bash
cp config/database.yml.example config/database.yml
```

Ví dụ cấu hình development mặc định:

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: rails_e_learning_development
  username: postgres
  password: password
  host: localhost
  port: 5432
```

Hoặc cấu hình qua ENV:

```bash
DB_USERNAME=postgres
DB_PASSWORD=password
DB_HOST=localhost
DB_PORT=5432
```

### 4. Cấu hình biến môi trường

Dự án có `.env.example` và custom initializer `config/initializers/figaro.rb` để đọc `config/application.yml` nếu file này tồn tại.

Có thể dùng một trong hai cách:

```bash
cp .env.example .env
```

hoặc tạo:

```bash
touch config/application.yml
```

Sau đó điền các key cần thiết theo phần [Biến môi trường](#biến-môi-trường).

### 5. Tạo database, migrate và seed

```bash
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

Có thể dùng lệnh gộp:

```bash
bundle exec rails db:prepare
bundle exec rails db:seed
```

### 6. Chạy server

```bash
bundle exec rails server
```

Mặc định ứng dụng chạy tại:

```text
http://localhost:3000
```

Health check:

```text
http://localhost:3000/health
```

## Chạy Bằng Docker

Dự án có sẵn `Dockerfile` và `docker-compose.yml`.

Chạy PostgreSQL và Rails app:

```bash
docker compose up --build
```

Trong container web, tạo database và seed:

```bash
docker compose exec web bundle exec rails db:create db:migrate db:seed
```

Thông tin PostgreSQL mặc định trong `docker-compose.yml`:

```text
host: db
port: 5432
database: rails_e_learning_development
username: postgres
password: password
```

Rails app chạy tại:

```text
http://localhost:3000
```

## Seed Dữ Liệu

Entry point:

```bash
bundle exec rails db:seed
```

Seed được chia trong `db/seeds/`:

| File | Nội dung |
| --- | --- |
| `00_helpers.rb` | Helper tạo tên, email, avatar, thumbnail, video YouTube, dữ liệu text |
| `01_organizations_and_users.rb` | Organizations và users |
| `02_categories.rb` | Categories |
| `03_courses_and_content.rb` | Courses, modules, lessons |
| `04_quizzes.rb` | Quizzes, questions, options |
| `05_enrollments.rb` | Enrollments, licenses, coupons |
| `06_reviews_and_comments.rb` | Reviews và comments |
| `07_progress.rb` | Progress tracking và quiz attempts |
| `08_learning_activities.rb` | Learning activities, streaks, goals |
| `09_certificates_and_wallets.rb` | Certificates, wallets, notifications |
| `10_misc.rb` | Discussions, study plans, recommendations |

Seed password mặc định trong helper:

```text
Education@2024!
```

Sau khi seed xong, script in thống kê số lượng user, admin, instructor, student, category, course, lesson, quiz, enrollment, review, certificate và study plan.

## Biến Môi Trường

Các biến môi trường được tham chiếu trong code:

### Rails và database

```text
RAILS_ENV
RAILS_MASTER_KEY
SECRET_KEY_BASE
DATABASE_URL
DB_USERNAME
DB_PASSWORD
DB_HOST
DB_PORT
DB_NAME
RAILS_MAX_THREADS
RAILS_MIN_THREADS
PORT
PIDFILE
APP_HOST
```

### Redis

```text
REDIS_URL
```

### Cloudinary

```text
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
```

### Stripe

```text
STRIPE_PUBLISHABLE_KEY
STRIPE_SECRET_KEY
STRIPE_SIGNING_SECRET
```

### Email

Production SMTP:

```text
SMTP_HOST
SMTP_PORT
SMTP_USERNAME
SMTP_PASSWORD
SMTP_DOMAIN
MAIL_FROM_ADDRESS
```

Development Mailtrap:

```text
MAILTRAP_HOST
MAILTRAP_PORT
MAILTRAP_USERNAME
MAILTRAP_PASSWORD
```

### AI Embedding

```text
EMBEDDING_PROVIDER
OPENAI_API_KEY
OPENAI_EMBEDDING_MODEL
GEMINI_API_KEY
GEMINI_EMBEDDING_MODEL
EMBEDDING_OPEN_TIMEOUT
EMBEDDING_READ_TIMEOUT
```

Giá trị mặc định đáng chú ý:

- `EMBEDDING_PROVIDER=openai`
- `OPENAI_EMBEDDING_MODEL=text-embedding-3-small`
- `GEMINI_EMBEDDING_MODEL=gemini-embedding-001`
- `EMBEDDING_OPEN_TIMEOUT=10`
- `EMBEDDING_READ_TIMEOUT=30`

### YouTube

```text
YOUTUBE_API_KEY
```

Service `YoutubeDurationService` dùng key này để lấy duration video.

### Sentry

```text
SENTRY_DSN
SENTRY_ENABLED
SENTRY_TRACES_SAMPLE_RATE
ENABLE_SENTRY_TEST_ROUTE
```

Khi `ENABLE_SENTRY_TEST_ROUTE=true`, route `/sentry-test` được bật để test capture lỗi.

## Lệnh Phát Triển Thường Dùng

Chạy server:

```bash
bundle exec rails server
```

Mở console:

```bash
bundle exec rails console
```

Tạo database:

```bash
bundle exec rails db:create
```

Chạy migration:

```bash
bundle exec rails db:migrate
```

Rollback migration gần nhất:

```bash
bundle exec rails db:rollback
```

Reset database và seed lại:

```bash
bundle exec rails db:reset
bundle exec rails db:seed
```

Precompile assets:

```bash
bundle exec rails assets:precompile
```

Chạy RuboCop:

```bash
bundle exec rubocop
```

## Test

Test hiện có tập trung ở service layer:

```text
test/services/learning/study_risk_detector_test.rb
test/services/recommendations/interaction_scorer_test.rb
test/services/study_plan_service_test.rb
```

Chạy toàn bộ test:

```bash
bundle exec rails test
```

Chạy một file test:

```bash
bundle exec rails test test/services/study_plan_service_test.rb
```

Chạy một test theo line:

```bash
bundle exec rails test test/services/study_plan_service_test.rb:10
```

## Background Jobs Và Rake Tasks

### Jobs

| Job | Queue | Chức năng |
| --- | --- | --- |
| `RecommendationJob` | `low` | Tính recommendation cá nhân hóa và cache vào `user_recommendations` |
| `CourseSimilarityJob` | `low` | Tính cosine similarity giữa các khóa học từ enrollment active |
| `StudyPlanReminderJob` | `default` | Tạo reminder cho lịch học hôm nay, overdue và deadline |
| `LicenseExpirationJob` | Theo cấu hình job | Xử lý license hết hạn |

### Recommendation tasks

Backfill embedding cho published courses:

```bash
bundle exec rake recommendations:embed_courses
```

Tùy chọn:

```bash
LIMIT=100 FORCE=true SLEEP=0.2 EMBEDDING_PROVIDER=openai bundle exec rake recommendations:embed_courses
```

Đánh giá offline recommender:

```bash
bundle exec rake recommendations:evaluate
```

Tùy chọn:

```bash
K=5 USER_LIMIT=200 bundle exec rake recommendations:evaluate
```

Kết quả CSV được xuất ra:

```text
tmp/recommendation_eval_results.csv
```

### Learning tasks

Tạo demo data cho behavior-based personalization:

```bash
bundle exec rake learning:demo_behavior_personalization
```

Tùy chọn:

```bash
EMAIL=student@example.com COURSE_ID=1 bundle exec rake learning:demo_behavior_personalization
```

### Cloudinary tasks

Dự án có `lib/tasks/cloudinary.rake` để hỗ trợ thao tác Cloudinary. Kiểm tra danh sách task:

```bash
bundle exec rake -T cloudinary
```

## Triển Khai

### Render

Dự án có `render.yaml` cấu hình:

- Web service tên `rails-elearning`.
- Runtime Ruby.
- Region Singapore.
- Build command:

```bash
bundle install && yarn install --frozen-lockfile && bundle exec rails assets:precompile
```

- Start command:

```bash
bundle exec puma -C config/puma.rb
```

- Health check:

```text
/health
```

- Render-managed PostgreSQL database `rails-elearning-db`.
- Render keyvalue Redis `rails-elearning-redis`.

Các biến bắt buộc khi deploy production:

- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- `DATABASE_URL`
- `REDIS_URL`
- `CLOUDINARY_*`
- `STRIPE_*`
- `YOUTUBE_API_KEY`
- `SMTP_*`
- `MAIL_FROM_ADDRESS`
- `SENTRY_DSN`

### Procfile

```Procfile
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
```

### Production behavior

- Static files được bật bằng `RAILS_SERVE_STATIC_FILES`.
- Log STDOUT được bật bằng `RAILS_LOG_TO_STDOUT`.
- Action Cable dùng Redis URL.
- Mailer host lấy từ `APP_HOST`.
- Sentry chỉ hoạt động khi có `SENTRY_DSN` và `SENTRY_ENABLED` không phải `false`.

## Ghi Chú Vận Hành

### Active Storage và Cloudinary

`config/storage.yml` định nghĩa service:

- `local`: lưu trên disk local.
- `test`: lưu vào `tmp/storage`.
- `cloudinary`: dùng custom service `CloudinaryHttp`.

Cloudinary yêu cầu:

```text
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
```

### Stripe webhook local

Khi test Stripe local, chạy Stripe CLI để forward webhook:

```bash
stripe listen --forward-to localhost:3000/webhooks
```

Sau đó cập nhật:

```text
STRIPE_SIGNING_SECRET=whsec_...
```

### Sentry test route

Route `/sentry-test` chỉ được mount khi:

```text
ENABLE_SENTRY_TEST_ROUTE=true
```

Không nên bật route này trong môi trường public trừ khi đang kiểm thử có kiểm soát.

### I18n

Ứng dụng cấu hình:

```ruby
config.i18n.default_locale = :en
config.i18n.available_locales = [:vi, :en]
```

File locale chính:

```text
config/locales/en.yml
config/locales/vi.yml
config/locales/devise.en.yml
```

### Time zone

Ứng dụng dùng:

```ruby
config.time_zone = "Hanoi"
config.active_record.default_timezone = :utc
```

### Health check

Endpoint:

```text
GET /health
```

Response:

```text
OK
```

## Checklist Cho Developer Mới

1. Cài Ruby `3.2.2`, PostgreSQL, Redis, Node.js, Yarn.
2. Chạy `bundle install` và `yarn install`.
3. Copy `config/database.yml.example` thành `config/database.yml`.
4. Tạo `.env` hoặc `config/application.yml`.
5. Điền DB, Cloudinary, Stripe và các key cần thiết.
6. Chạy `bundle exec rails db:create db:migrate db:seed`.
7. Chạy `bundle exec rails test`.
8. Chạy `bundle exec rails server`.
9. Mở `http://localhost:3000`.

## Tài Liệu Liên Quan Trong Repo

Repo còn có một số file ghi chú/kế hoạch có thể hữu ích:

- `deploy.md`
- `PROJECT_REPORT_KNOWLEDGE.md`
- `recommendation_evaluation_report.md`
- `personalization_learning_report.md`
- `plan.md`
- `plan_version_2.md`
- `plan3_instructor_b2b.md`
- `rcm.md`

Các file này không thay thế README, nhưng giúp hiểu thêm lịch sử phát triển các module recommendation, personalization, instructor và B2B.
