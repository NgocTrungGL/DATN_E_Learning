# Kế hoạch triển khai: AI Course Recommendation

> **Phạm vi:** Dự án đang ở giai đoạn phát triển, dữ liệu nhỏ.
> Ưu tiên đơn giản, chạy được, dễ mở rộng — không over-engineer.

---

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Cấu trúc thư mục](#2-cấu-trúc-thư-mục)
3. [Bảng dữ liệu mới cần thêm](#3-bảng-dữ-liệu-mới-cần-thêm)
4. [Các bước triển khai theo thứ tự](#4-các-bước-triển-khai-theo-thứ-tự)
5. [Chi tiết từng thành phần](#5-chi-tiết-từng-thành-phần)
6. [Luồng dữ liệu end-to-end](#6-luồng-dữ-liệu-end-to-end)
7. [Điểm cần chú ý khi triển khai](#7-điểm-cần-chú-ý-khi-triển-khai)
8. [Chiến lược theo giai đoạn](#8-chiến-lược-theo-giai-đoạn)
9. [Kiểm thử](#9-kiểm-thử)
10. [Checklist trước khi deploy](#10-checklist-trước-khi-deploy)

---

## 1. Tổng quan kiến trúc

### Nguyên tắc cốt lõi

```
KHÔNG bao giờ tính toán recommendation trong web request.
Chỉ ĐỌC kết quả đã pre-compute từ DB.
```

### Ba thuật toán kết hợp (Hybrid)

```
Behavioral signals
  (enrollments, reviews, wishlists, progress, cart, quizzes)
          │
          ▼
┌─────────────────┬──────────────────┬─────────────────┐
│ Content-based   │  Item-based CF   │ Popularity score │
│ (category       │  (co-enrollment  │ (Bayesian avg    │
│  matching)      │   cosine sim.)   │  + volume)       │
└────────┬────────┴────────┬─────────┴────────┬─────────┘
         └────────────────▼──────────────────┘
                  Weighted score fusion
                  α·CF + β·content + γ·popularity
                          │
                          ▼
               Ranked course recommendations
               (đã lọc course đã enroll)
```

### Adaptive weights — tự động điều chỉnh theo mức độ tương tác

| Số interaction của user | α (CF) | β (Content) | γ (Popularity) | Ý nghĩa |
|---|---|---|---|---|
| ≥ 5 enrollments/wishlists | 0.50 | 0.35 | 0.15 | Đủ data, tin CF |
| 2–4 | 0.20 | 0.50 | 0.30 | Data vừa, lean content |
| 0–1 (new user) | 0.00 | 0.30 | 0.70 | Cold start, dùng popularity |

---

## 2. Cấu trúc thư mục

```
app/
├── controllers/
│   └── api/v1/
│       └── recommendations_controller.rb     ← endpoint duy nhất
│
├── models/
│   ├── user_recommendation.rb                ← kết quả pre-computed
│   └── course_similarity.rb                  ← similarity matrix
│
├── services/
│   └── recommendations/
│       ├── result.rb                         ← value object (Struct)
│       ├── interaction_scorer.rb             ← chuyển signals → scores
│       ├── content_filter.rb                 ← thuật toán content-based
│       ├── collaborative_filter.rb           ← thuật toán item-based CF
│       ├── popularity_scorer.rb              ← Bayesian popularity
│       ├── score_fuser.rb                    ← kết hợp 3 thuật toán
│       ├── computer.rb                       ← orchestrator (gọi từ job)
│       └── engine.rb                         ← façade (gọi từ controller)
│
└── jobs/
    ├── recommendation_job.rb                 ← per-user, trigger by events
    └── course_similarity_job.rb              ← global, chạy weekly

config/
└── routes.rb                                 ← thêm 1 route

db/
└── migrate/
    └── YYYYMMDD_create_recommendation_tables.rb
```

---

## 3. Bảng dữ liệu mới cần thêm

### 3.1 `user_recommendations` — kết quả pre-computed

```ruby
create_table :user_recommendations do |t|
  t.bigint   :user_id,     null: false
  t.bigint   :course_id,   null: false
  t.decimal  :score,       precision: 8, scale: 4
  t.string   :reason_type  # "cf" | "content" | "popular"
  t.datetime :computed_at, null: false
  t.timestamps
end

add_index :user_recommendations, [:user_id, :score]
add_index :user_recommendations, [:user_id, :course_id], unique: true
add_foreign_key :user_recommendations, :users
add_foreign_key :user_recommendations, :courses
```

**Mục đích:** Lưu trữ top-20 khuyến nghị đã tính sẵn cho mỗi user.
**TTL:** 24 giờ — sau đó Engine sẽ trigger recompute và fallback tạm về popularity.

### 3.2 `course_similarities` — độ tương đồng giữa các course

```ruby
create_table :course_similarities do |t|
  t.bigint   :course_a_id, null: false
  t.bigint   :course_b_id, null: false
  t.decimal  :score,       precision: 8, scale: 6, null: false  # 0.0 – 1.0
  t.datetime :computed_at
  t.timestamps
end

add_index :course_similarities, [:course_a_id, :score]
add_index :course_similarities, [:course_a_id, :course_b_id], unique: true
add_foreign_key :course_similarities, :courses, column: :course_a_id
add_foreign_key :course_similarities, :courses, column: :course_b_id
```

**Mục đích:** Kết quả cosine similarity từ `CourseSimilarityJob`.
**Lưu ý:** Lưu cả 2 chiều (A→B và B→A) để query nhanh hơn bằng `course_a_id`.

---

## 4. Các bước triển khai theo thứ tự

Làm theo thứ tự này để có thể test từng phần trước khi gộp lại.

```
Bước 1  ──  Migration + Models
Bước 2  ──  Value object (Result struct)
Bước 3  ──  InteractionScorer
Bước 4  ──  PopularityScorer
Bước 5  ──  Engine (đọc pre-computed + fallback popularity)
Bước 6  ──  Controller + Route  ← test được API ở đây
Bước 7  ──  ContentFilter
Bước 8  ──  CollaborativeFilter
Bước 9  ──  ScoreFuser + Computer
Bước 10 ──  RecommendationJob (per-user)
Bước 11 ──  CourseSimilarityJob (global)
Bước 12 ──  Trigger callbacks trên model
```

> **Tại sao làm Bước 6 sớm?**
> Sau Bước 6 bạn đã có API hoạt động (dùng popularity fallback).
> Frontend có thể tích hợp ngay trong khi backend tiếp tục hoàn thiện các thuật toán.

---

## 5. Chi tiết từng thành phần

### 5.1 `Result` — Value Object

```ruby
# app/services/recommendations/result.rb
module Recommendations
  Result = Struct.new(:course_id, :course, :score, :reason_type, keyword_init: true)
end
```

Một Struct đơn giản, không kế thừa ActiveRecord.
Tất cả service trả về `Array<Result>` — interface nhất quán cho `ScoreFuser`.

---

### 5.2 `InteractionScorer` — Bộ chấm điểm tương tác

Chuyển toàn bộ hành vi của user thành `Hash{ course_id => Float }`.

**Bảng điểm:**

| Hành vi | Điểm |
|---|---|
| Enrolled + hoàn thành 100% | +5.0 |
| Enrolled + đang học (> 0%) | +4.0 |
| Enrolled + chưa bắt đầu | +2.0 |
| Review 5 sao | +5.0 |
| Review 4 sao | +3.0 |
| Review 3 sao | +1.0 |
| Review 1–2 sao | **−2.0** (negative signal!) |
| Wishlist | +3.0 |
| Cart | +2.0 |
| Đã viết note | +1.0 |
| Quiz passed | +1.0 |

**Lưu ý:** Negative score cho review thấp là cần thiết.
Nếu user rate 1 sao → đừng recommend course cùng loại đó.

---

### 5.3 `ContentFilter` — Lọc theo danh mục

**Logic:**
1. Lấy `category_id` từ các course user đã enroll + wishlist
2. Traverse lên parent category (schema có `categories.parent_id`)
   → Nếu user học "Python Basics" (Python > Programming), cũng boost các course Python khác và Programming khác
3. Score = `(direct_weight + parent_weight * 0.5) / total_weight`

**Ví dụ thực tế:**
```
User đã học: Python Basics (category: Python, parent: Programming)
Kết quả boost:
  - Django Web Dev (Python)       → score cao
  - Data Science with Python (Python) → score cao
  - JavaScript Basics (Programming)  → score trung bình (parent match)
  - Cooking 101 (unrelated)          → score = 0
```

---

### 5.4 `CollaborativeFilter` — Lọc cộng tác

**Logic:**
1. Lấy list course user đã tương tác từ `InteractionScorer`
2. Query `course_similarities` để tìm course tương tự
3. Exclude course user đã tương tác rồi

**Phụ thuộc:** Cần `CourseSimilarityJob` đã chạy ít nhất 1 lần.
Nếu bảng `course_similarities` rỗng → trả `[]` → ScoreFuser tự động dùng content + popularity bù.

---

### 5.5 `PopularityScorer` — Điểm nổi bật

Dùng **Bayesian Average** thay vì raw average để tránh course ít review bị overrate:

```
bayesian_score = (C × global_mean + n × avg_rating) / (C + n)

C = 5 (prior: giả sử có 5 review tại mức trung bình toàn hệ thống)
n = số review thực của course
```

Kết hợp với enrollment volume (log-normalized):
```
final_score = 0.7 × (bayesian / 5.0) + 0.3 × log10(enrollments + 1) / 5
```

---

### 5.6 `ScoreFuser` — Kết hợp điểm

```ruby
fused_score = α × cf_score + β × content_score + γ × popularity_score
```

Nếu một thuật toán không trả về kết quả cho course X (ví dụ CF chưa có data),
score tương ứng = 0.0 — course vẫn được rank dựa trên 2 thuật toán còn lại.

`reason_type` = thuật toán đóng góp điểm cao nhất → dùng để debug và hiển thị UI ("Vì bạn đã học X", "Phổ biến", v.v.)

---

### 5.7 `Computer` — Điều phối thuật toán

```
Computer#call(limit: 20)
  1. Resolve weights dựa trên số interaction của user
  2. Nếu alpha > 0 hoặc beta > 0:
       - Chạy CollaborativeFilter
       - Chạy ContentFilter
       - Chạy PopularityScorer
       - Gộp qua ScoreFuser
  3. Nếu cold start (alpha=0, beta=0):
       - Chỉ chạy PopularityScorer (tiết kiệm tài nguyên)
  4. Sort by score desc, lấy limit kết quả
```

> `Computer` **không bao giờ** được gọi từ Controller.
> Chỉ được gọi từ `RecommendationJob`.

---

### 5.8 `Engine` — Cổng vào cho Controller

```
Engine#call(limit: 10)
  1. Query UserRecommendation WHERE user_id = ? AND computed_at > 24.hours.ago
     JOIN courses WHERE status = published
     ORDER BY score DESC LIMIT limit
  2. Nếu có kết quả → trả về ngay
  3. Nếu rỗng hoặc stale:
       → Enqueue RecommendationJob.perform_later(user.id)  (async)
       → Trả về PopularityScorer fallback ngay lập tức (user không thấy trống)
```

---

### 5.9 `RecommendationJob` — Job per-user

```
Trigger: sau khi user enroll / review / wishlist
Queue: :low (không urgent)

Thực thi:
  1. Load user
  2. Gọi Computer.new(user).call(limit: 20)
  3. Transaction:
       DELETE FROM user_recommendations WHERE user_id = ?
       INSERT INTO user_recommendations (bulk insert)
```

**Quan trọng:** Dùng `insert_all` thay vì `create` từng record để tránh N queries.

---

### 5.10 `CourseSimilarityJob` — Job global (weekly)

```
Schedule: mỗi tuần (Sidekiq-Cron hoặc whenever gem)
Queue: :low

Thực thi:
  1. Build interaction matrix từ enrollments + reviews + wishlists
     → Hash{ course_id => { user_id => score } }
  2. Tính cosine similarity cho mọi cặp course
  3. Lọc similarity < 0.05 (không đáng kể)
  4. Transaction: DELETE ALL → insert_all kết quả mới
```

**Cosine similarity:**
```
sim(A, B) = Σ(score_A[u] × score_B[u]) / (|A| × |B|)
           (chỉ tính trên user đã tương tác cả A lẫn B)
```

---

## 6. Luồng dữ liệu end-to-end

```
USER ACTION (enroll / review / wishlist)
          │
          ▼
  Model callback: after_create_commit
  → RecommendationJob.perform_later(user_id)
          │
          ▼ (background, queue :low)
  RecommendationJob#perform
  → Recommendations::Computer.new(user).call
          │
    ┌─────┴──────┐
    │ Resolve    │ α=0.5, β=0.35, γ=0.15 (ví dụ user có ≥5 interactions)
    └─────┬──────┘
          │
    ┌─────┴────────────────────────────────────────────────┐
    │ CollaborativeFilter  ContentFilter  PopularityScorer  │
    └─────┬──────────────────────┬────────────────┬─────────┘
          └──────────────────────▼────────────────┘
                         ScoreFuser
                               │
                               ▼
                    INSERT INTO user_recommendations
                    (20 rows, score DESC)

──────────────────────────────────────────────────────────

USER REQUEST: GET /api/v1/recommendations
          │
          ▼
  RecommendationsController#index
  → Recommendations::Engine.new(current_user).call(limit: 10)
          │
          ▼
  Query user_recommendations WHERE computed_at > 24h ago
          │
    ┌─────┴──────────────────────────────────┐
    │ Có data?                               │
    │ YES → trả về JSON ngay                 │
    │ NO  → enqueue job + trả popularity     │
    └────────────────────────────────────────┘

──────────────────────────────────────────────────────────

WEEKLY SCHEDULE: CourseSimilarityJob
  → Rebuild course_similarities từ đầu
  → ~O(n²) trên số lượng course (ổn với dự án nhỏ)
```

---

## 7. Điểm cần chú ý khi triển khai

### 7.1 Thứ tự migration quan trọng

Chạy migration trước khi deploy code service. Nếu deploy ngược lại,
`Engine` sẽ query bảng chưa tồn tại → 500 error.

```bash
rails db:migrate
# Sau đó mới deploy code
```

### 7.2 Sidekiq / background job

Hệ thống này **phụ thuộc hoàn toàn** vào background job.
Nếu chưa cài Sidekiq, dùng `perform_now` thay `perform_later` trong giai đoạn dev,
nhưng **bắt buộc** phải có async queue trên production.

```ruby
# Kiểm tra gem Gemfile
gem 'sidekiq'

# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

### 7.3 Cold start — user mới

User mới = 0 interaction → weights: α=0, β=0, γ=1.0 → chỉ popularity.
Đây là hành vi đúng. Đừng cố recommend khi chưa có data.

Tuy nhiên, sau khi user enroll lần đầu → job được trigger → lần sau đã có content-based.
Vòng loop này tự cải thiện theo thời gian.

### 7.4 Course_similarities rỗng lúc đầu

Khi deploy lần đầu, bảng `course_similarities` sẽ rỗng.
`CollaborativeFilter` trả `[]` → ScoreFuser bỏ qua phần CF → vẫn chạy được.

**Cần chạy thủ công lần đầu:**
```ruby
CourseSimilarityJob.perform_now  # trong Rails console
```

### 7.5 Negative review signal

Review 1–2 sao trừ điểm (−2.0). Điều này có nghĩa:
- Một course bị nhiều user rate thấp sẽ có interaction score âm
- CF sẽ **không** recommend nó → đúng
- Tuy nhiên course vẫn xuất hiện trong Popularity nếu `avg_rating` cao
  → Bayesian average tự xử lý: nhiều low review = avg thấp = score thấp

### 7.6 Lọc course đã enroll

**Bắt buộc** exclude course user đã có `enrollment` (kể cả status `pending`).
Làm ở cả hai nơi:
1. `PopularityScorer` — truyền `exclude_enrolled_for: user`
2. `Engine` — query `JOIN courses WHERE id NOT IN (SELECT course_id FROM enrollments WHERE user_id = ?)`

Nếu chỉ lọc ở 1 nơi → có thể vẫn bị lọt qua khi fallback.

### 7.7 Chỉ recommend course `published`

Thêm scope vào `Course` model nếu chưa có:
```ruby
# Kiểm tra giá trị enum published trong schema của bạn
# courses.status là integer, default 0
scope :published, -> { where(status: 1) }  # điều chỉnh theo enum thực tế
```

Luôn `merge(Course.published)` khi query `user_recommendations`.

### 7.8 insert_all và timestamps

`insert_all` không tự điền `created_at`, `updated_at`.
Phải tự thêm vào hash:

```ruby
rows = results.map do |r|
  {
    user_id:     user.id,
    course_id:   r.course_id,
    score:       r.score,
    reason_type: r.reason_type,
    computed_at: Time.current,
    created_at:  Time.current,   # bắt buộc
    updated_at:  Time.current    # bắt buộc
  }
end
UserRecommendation.insert_all(rows)
```

### 7.9 Race condition trên job

Nếu user review 3 course trong 1 phút → 3 jobs cùng enqueue → 3 jobs cùng chạy song song
→ có thể ghi đè lẫn nhau.

**Giải pháp đơn giản (dự án nhỏ):** Thêm `5.minutes` debounce:
```ruby
# Trong model callback, chỉ queue nếu không có job pending gần đây
after_create_commit do
  last_computed = UserRecommendation.where(user_id: user_id).maximum(:computed_at)
  unless last_computed&.> 5.minutes.ago
    RecommendationJob.perform_later(user_id)
  end
end
```

Hoặc dùng gem `sidekiq-unique-jobs` nếu cần robust hơn.

### 7.10 Khi nào nên chạy CourseSimilarityJob

- **Lần đầu deploy:** Chạy thủ công trong console
- **Sau đó:** Mỗi tuần là đủ (dữ liệu không thay đổi nhanh)
- **Trigger thêm:** Khi số lượng course tăng > 20% kể từ lần chạy cuối

```ruby
# Thêm vào config/schedule.rb (whenever gem)
every 1.week, at: '3:00 am' do
  runner "CourseSimilarityJob.perform_later"
end
```

---

## 8. Chiến lược theo giai đoạn

### Giai đoạn 1 — MVP (làm ngay)

**Mục tiêu:** API chạy được, trả về kết quả có nghĩa.

- [x] Migration tạo 2 bảng mới
- [x] `PopularityScorer` + `Engine` (fallback only)
- [x] Controller + Route
- [x] `RecommendationJob` (chỉ gọi PopularityScorer)

Kết quả: User mới thấy danh sách course phổ biến. Đơn giản nhưng hoạt động.

### Giai đoạn 2 — Personalization (sau khi có > 50 users)

**Mục tiêu:** Recommendation dựa trên lịch sử cá nhân.

- [x] `InteractionScorer`
- [x] `ContentFilter`
- [x] `ScoreFuser`
- [x] Cập nhật `Computer` dùng content + popularity
- [x] Model callbacks trên `Enrollment`, `Review`, `Wishlist`

Kết quả: User thấy course phù hợp với category mình đã học.

### Giai đoạn 3 — Collaborative Filtering (sau khi có > 200 enrollments)

**Mục tiêu:** "Người học giống bạn cũng học..."

- [x] `CollaborativeFilter`
- [x] `CourseSimilarityJob` (weekly)
- [x] Cập nhật `Computer` dùng đủ 3 thuật toán

Kết quả: Recommendation thực sự thông minh, dựa trên patterns cộng đồng.

---

## 9. Kiểm thử

### 9.1 Test thủ công trong Rails console

```ruby
# Tạo test data
user = User.find(1)

# Chạy Computer trực tiếp
results = Recommendations::Computer.new(user).call(limit: 10)
results.each { |r| puts "#{r.course.title} | #{r.score.round(3)} | #{r.reason_type}" }

# Test từng thuật toán riêng
Recommendations::PopularityScorer.new.call(exclude_enrolled_for: user).first(5).map { |r| [r.course.title, r.score.round(3)] }
Recommendations::ContentFilter.new(user).call.first(5).map { |r| [r.course.title, r.score.round(3)] }
Recommendations::CollaborativeFilter.new(user).call.first(5).map { |r| [r.course.title, r.score.round(3)] }

# Chạy full job
RecommendationJob.perform_now(user.id)
UserRecommendation.where(user: user).order(score: :desc).includes(:course).map { |r| "#{r.score.round(3)} | #{r.reason_type} | #{r.course.title}" }

# Test Engine
Recommendations::Engine.new(user).call(limit: 10).map { |r| [r.course.title, r.score.round(3)] }
```

### 9.2 Các trường hợp cần test

| Trường hợp | Kết quả mong đợi |
|---|---|
| User mới (0 enrollments) | Trả về popular courses |
| User có 1–4 enrollments | Mix content + popularity, không có CF |
| User có ≥ 5 enrollments | Đủ 3 thuật toán |
| User đã enroll tất cả course | Trả `[]` hoặc rất ít kết quả |
| `course_similarities` rỗng | CF trả `[]`, vẫn chạy content + popularity |
| Course unpublished | Không bao giờ xuất hiện trong kết quả |
| User review 1 sao | Course đó không được recommend course cùng loại |

### 9.3 RSpec (gợi ý cấu trúc)

```ruby
# spec/services/recommendations/engine_spec.rb
RSpec.describe Recommendations::Engine do
  describe "#call" do
    context "when no pre-computed data" do
      it "falls back to popularity and enqueues job" do
        expect(RecommendationJob).to receive(:perform_later).with(user.id)
        results = described_class.new(user).call
        expect(results).to all(be_a(Recommendations::Result))
        expect(results.map(&:reason_type)).to all(eq("popular"))
      end
    end

    context "when fresh pre-computed data exists" do
      it "returns pre-computed results without enqueuing" do
        create(:user_recommendation, user: user, computed_at: 1.hour.ago)
        expect(RecommendationJob).not_to receive(:perform_later)
        described_class.new(user).call
      end
    end
  end
end
```

---

## 10. Checklist trước khi deploy

### Database
- [ ] Migration chạy thành công (`rails db:migrate`)
- [ ] 2 bảng mới tồn tại: `user_recommendations`, `course_similarities`
- [ ] Index đã được tạo đúng

### Background Job
- [ ] Sidekiq (hoặc job adapter khác) đã config
- [ ] Queue `:low` được xử lý
- [ ] `CourseSimilarityJob.perform_now` đã chạy thủ công lần đầu

### Models
- [ ] `Course.published` scope trả đúng (check integer value của status)
- [ ] Callback `after_create_commit` đã thêm vào `Enrollment`, `Review`, `Wishlist`
- [ ] `UserRecommendation` và `CourseSimilarity` models có đúng `belongs_to`

### Service Layer
- [ ] `Engine` trả kết quả với user có data
- [ ] `Engine` fallback về popularity khi không có pre-computed data
- [ ] Không có course đã enrolled nào lọt vào kết quả
- [ ] Không có course unpublished nào lọt vào kết quả

### API
- [ ] `GET /api/v1/recommendations` trả `200` với authenticated user
- [ ] `GET /api/v1/recommendations` trả `401` với unauthenticated user
- [ ] Response JSON có đúng structure
- [ ] Param `?limit=N` hoạt động, clamp về [1, 50]

### Edge Cases
- [ ] User mới (0 enrollments) → trả popular, không crash
- [ ] `course_similarities` rỗng → vẫn chạy được
- [ ] User đã enroll tất cả published course → trả `[]`, không crash

---

## Ghi chú bổ sung

**Về `reason_type` trên frontend:**
Trường này dùng để hiển thị lý do recommend, giúp UX tốt hơn:
- `"cf"` → "Người học giống bạn cũng quan tâm đến khóa này"
- `"content"` → "Phù hợp với lĩnh vực bạn đang học"
- `"popular"` → "Khóa học được yêu thích"

**Về việc mở rộng sau này:**
Khi dữ liệu lớn hơn (> 500k enrollments), phần cần refactor đầu tiên là
`CourseSimilarityJob#build_interaction_matrix` — chuyển từ load vào Ruby memory
sang thuần SQL với CTE/materialized view.
Phần còn lại của kiến trúc không cần thay đổi.
