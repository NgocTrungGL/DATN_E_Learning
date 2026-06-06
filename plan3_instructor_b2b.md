# Kế Hoạch Phát Triển Instructor & B2B Module
**Phiên bản:** 3.0 — Instructor & Enterprise
**Ngày:** 25/05/2026
**Trạng thái:** Bản nháp, chờ duyệt

---

## I. Tổng Quan Hiện Trạng

### 1.1 Instructor Module — Hiện Có

| Thành phần | File | Trạng thái | Gap |
|------------|------|-------------|-----|
| Dashboard | `instructor/dashboard/index.html.erb` | Cơ bản | Chỉ list courses, không có KPI |
| Courses CRUD | `instructor/courses/` | Hoàn thiện | UI form còn đơn giản |
| Course Modules CRUD | `instructor/course_modules/` | Hoàn thiện | Chỉ form, không drag-drop |
| Lessons CRUD | `instructor/lessons/` | Hoàn thiện | Không có preview |
| Quizzes CRUD | `instructor/quizzes/` | Hoàn thiện | Question bank chưa tối ưu |
| Questions CRUD | `instructor/questions/` | Hoàn thiện | Không có bulk import |
| Coupons CRUD | `instructor/coupons/` | Hoàn thiện | Không có analytics |
| Revenues | `instructor/revenues/index.html.erb` | Cơ bản | Chỉ 1 chart 30 ngày |
| Payouts | `instructor/payouts/` | Hoàn thiện | — |
| Instructor Registration | `instructor_registrations/` | Hoàn thiện | — |

### 1.2 B2B Module — Hiện Có

| Thành phần | File | Trạng thái | Gap |
|------------|------|-------------|-----|
| B2B Registration | `b2b/registrations/` | Cơ bản | Form đơn giản |
| Business Dashboard | `business/dashboard/index.html.erb` | Rất cơ bản | Chỉ đếm employees |
| Employees CRUD | `business/employees/` | Cơ bản | Không bulk import |
| Licenses | `business/licenses/` | Cơ bản | Không có expiration |
| Course Market | `business/course_market/` | Cơ bản | Chỉ mua license đơn |

### 1.3 Models Liên Quan

```
InstructorModule
├── InstructorProfile (bio, bank, status: pending/approved/rejected)
├── Course (creator_id, status, price)
├── Quiz, Question, Lesson, CourseModule
├── Wallet, WalletTransaction
└── PayoutRequest

B2BModule
├── Organization (name, domain, plan: free/standard/enterprise)
├── License (organization_id, course_id, user_id, status: available/assigned/expired)
├── User (role: company_admin, employee, organization_id)
└── CourseMarket (danh sach khoa hoc de mua license)
```

---

## II. Mục Tiêu Phát Triển

### Instructor Module Goals
1. Dashboard với KPI tức thì (revenue, students, completion rate)
2. Course Builder với drag-drop UI
3. Student Analytics chi tiết (ai học, tiến độ, điểm quiz)
4. Coupon Analytics (usage, conversion, revenue)
5. Course Performance metrics (best seller, rating distribution)
6. Public Instructor Profile page
7. Instructor Earnings breakdown (gross, net, tax)

### B2B Module Goals
1. Enterprise Dashboard với training ROI
2. Employee Progress Report (ai học, ai bỏ)
3. Bulk CSV import employees
4. License expiration tracking + alerts
5. Custom Learning Path cho tổ chức
6. Organization branding (logo, colors)
7. Course assignment workflow nâng cao

---

## III. Instructor Module — Chi Tiết Từng Feature

### I-1. Instructor Dashboard Nâng Cấp (KPI Cards)

**Effort:** 2 ngày
**Priority:** CAO
**Routes:** `instructor/dashboard`

#### 3.1.1 KPI Cards

Thêm 4 KPI cards vào `instructor/dashboard/index.html.erb`:

```
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ 💰 Total Revenue │ │ 👥 Total Students│ │ 📚 Active Courses│ │ ⭐ Avg Rating   │
│    12,500,000₫  │ │       342       │ │        8        │ │       4.7       │
│  ↑ 15% vs last │ │  ↑ 8% vs last  │ │  vs 7 last mon │ │  vs 4.5 last   │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
```

#### 3.1.2 Revenue Model Addition

```ruby
# app/models/user.rb (existing)
has_many :courses, foreign_key: :creator_id

# Tạo helper method trong User model hoặc InstructorDashboardDecorator

def total_revenue
  courses.sum do |course|
    course.enrollments.sum do |e|
      e.price.to_i * 0.7  # 70% cho instructor
    end
  end
end

def total_students
  courses.joins(:enrollments).distinct.count(:user_id)
end

def active_courses_count
  courses.where(status: :published).count
end

def average_rating
  courses.average(:average_rating).to_f.round(1)
end
```

#### 3.1.3 Revenue Chart Enhancement

Nâng cấp chart trong `instructor/revenues/index.html.erb`:

```erb
<%# Hiện tại: chỉ 30 ngày %>
<%# Nâng cấp: cho chọn range (7d, 30d, 90d, 1y, all) %>

<div class="revenue-chart">
  <div class="chart-header">
    <h3>Doanh thu</h3>
    <div class="chart-range-selector">
      <%= link_to "7 ngày", instructor_revenues_path(range: "7d"), class: "range-btn #{"active" if params[:range] == "7d"}" %>
      <%= link_to "30 ngày", instructor_revenues_path(range: "30d"), class: "range-btn #{"active" if params[:range] == "30d"}" %>
      <%= link_to "90 ngày", instructor_revenues_path(range: "90d"), class: "range-btn" %>
      <%= link_to "1 năm", instructor_revenues_path(range: "1y"), class: "range-btn" %>
      <%= link_to "Tất cả", instructor_revenues_path(range: "all"), class: "range-btn" %>
    </div>
  </div>
  <%= column_chart @revenue_data,
        height: "300px",
        colors: ["#2563eb"],
        thousands: ".",
        prefix: "",
        suffix: "₫" %>
</div>
```

#### 3.1.4 Recent Activity Feed

Thêm phần "Hoạt động gần đây":

```erb
<div class="recent-activity">
  <h4>Hoạt động gần đây</h4>
  <ul class="activity-list">
    <% @recent_activities.each do |activity| %>
      <li class="activity-item">
        <span class="activity-icon"><%= activity_icon(activity.type) %></span>
        <span class="activity-text">
          <strong><%= activity.user_name %></strong>
          <%= activity.description %>
          <%= time_ago_in_words(activity.created_at) %> trước
        </span>
      </li>
    <% end %>
  </ul>
</div>
```

#### 3.1.5 Quick Stats Sidebar

```erb
<div class="dashboard-sidebar">
  <%# Top performing course %>
  <div class="quick-stat-card">
    <span class="stat-label">Khóa học bán chạy nhất</span>
    <span class="stat-value"><%= @top_course&.title %></span>
    <span class="stat-meta"><%= @top_course&.enrollments_count %> học viên</span>
  </div>

  <%# Pending payouts %>
  <div class="quick-stat-card">
    <span class="stat-label">Số dư ví</span>
    <span class="stat-value"><%= number_to_currency(current_user.wallet.balance, unit: "đ", precision: 0) %></span>
    <%= link_to "Rút tiền", new_instructor_payout_path, class: "btn-link" %>
  </div>

  <%# Pending course reviews %>
  <div class="quick-stat-card">
    <span class="stat-label">Khóa chờ duyệt</span>
    <span class="stat-value"><%= @pending_courses_count %></span>
    <% if @pending_courses_count > 0 %>
      <%= link_to "Xem ngay", instructor_courses_path(status: :pending), class: "badge badge-warning" %>
    <% end %>
  </div>
</div>
```

#### 3.1.6 SCSS

```scss
// app/assets/stylesheets/pages/instructor/_dashboard.scss

.instructor-dashboard {
  &__kpi-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 1.5rem;
    margin-bottom: 2rem;

    @media (max-width: 1024px) {
      grid-template-columns: repeat(2, 1fr);
    }
    @media (max-width: 640px) {
      grid-template-columns: 1fr;
    }
  }

  &__kpi-card {
    background: white;
    border-radius: $radius-md;
    padding: 1.5rem;
    box-shadow: $shadow-sm;
    transition: box-shadow 0.2s ease;

    &:hover { box-shadow: $shadow-md; }

    .kpi-icon {
      font-size: 1.5rem;
      margin-bottom: 0.75rem;
    }

    .kpi-value {
      font-size: 1.75rem;
      font-weight: 700;
      color: var(--text-dark);
      margin-bottom: 0.25rem;
    }

    .kpi-label {
      font-size: 0.85rem;
      color: var(--text-muted);
    }

    .kpi-change {
      font-size: 0.8rem;
      margin-top: 0.5rem;
      &.up { color: $success; }
      &.down { color: $danger; }
    }
  }

  &__chart-section {
    background: white;
    border-radius: $radius-md;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
  }

  &__chart-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;

    h3 { margin: 0; }
  }

  &__range-selector {
    display: flex;
    gap: 0.5rem;

    .range-btn {
      padding: 0.4rem 0.75rem;
      border-radius: 6px;
      font-size: 0.85rem;
      color: var(--text-muted);
      text-decoration: none;
      transition: all 0.15s;

      &:hover { background: var(--bg); }
      &.active {
        background: var(--primary);
        color: white;
      }
    }
  }

  &__activity-feed {
    background: white;
    border-radius: $radius-md;
    padding: 1.5rem;

    .activity-list {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .activity-item {
      display: flex;
      align-items: flex-start;
      gap: 0.75rem;
      padding: 0.75rem 0;
      border-bottom: 1px solid var(--border);

      &:last-child { border-bottom: none; }
    }
  }

  &__sidebar {
    .quick-stat-card {
      background: white;
      border-radius: $radius-md;
      padding: 1.25rem;
      margin-bottom: 1rem;
      box-shadow: $shadow-sm;

      .stat-label {
        font-size: 0.8rem;
        color: var(--text-muted);
        display: block;
        margin-bottom: 0.25rem;
      }

      .stat-value {
        font-size: 1.1rem;
        font-weight: 600;
        color: var(--text-dark);
        display: block;
        margin-bottom: 0.25rem;
      }

      .stat-meta {
        font-size: 0.8rem;
        color: var(--text-muted);
      }
    }
  }
}
```

---

### I-2. Course Builder Drag-Drop UI

**Effort:** 5 ngày
**Priority:** CAO
**Routes:** `instructor/courses/:id/builder`

#### 3.2.1 Routes

```ruby
# config/routes.rb
namespace :instructor do
  resources :courses do
    member do
      get  :builder        # Drag-drop course builder
      get  :students       # Danh sach hoc vien
      patch:sort_modules   # AJAX sort modules
      patch:sort_lessons   # AJAX sort lessons
    end
  end
end
```

#### 3.2.2 CourseBuilderController

```ruby
# app/controllers/instructor/course_builder_controller.rb
class Instructor::CourseBuilderController < Instructor::BaseController
  before_action :set_course

  def show
    @modules = @course.course_modules.includes(:lessons).order(:order_index)
  end

  def sort_modules
    ActiveRecord::Base.transaction do
      params[:module_order].each_with_index do |module_id, index|
        @course.course_modules.find(module_id).update!(order_index: index + 1)
      end
    end
    head :ok
  end

  def sort_lessons
    ActiveRecord::Base.transaction do
      params[:lesson_order].each_with_index do |lesson_data, index|
        lesson = Lesson.find(lesson_data[:id])
        lesson.update!(
          order_index: index + 1,
          course_module_id: lesson_data[:module_id]
        )
      end
    end
    head :ok
  end

  private

  def set_course
    @course = current_user.courses.find(params[:course_id])
    authorize! :manage, @course
  end
end
```

#### 3.2.3 Course Builder View

```erb
<%# app/views/instructor/course_builder/show.html.erb %>
<div class="course-builder" data-controller="sortable">
  <div class="builder-header">
    <h1>Xây dựng khóa học: <%= @course.title %></h1>
    <div class="builder-actions">
      <%= link_to "Quay lại", instructor_course_path(@course), class: "btn btn-outline" %>
      <%= link_to "Xem trước", course_path(@course), class: "btn btn-outline", target: "_blank" %>
      <% if @course.published? %>
        <span class="badge badge-success">Đã xuất bản</span>
      <% elsif @course.pending? %>
        <span class="badge badge-warning">Chờ duyệt</span>
      <% else %>
        <span class="badge badge-secondary">Bản nháp</span>
      <% end %>
    </div>
  </div>

  <div class="builder-content">
    <%# Sidebar: Add new items %>
    <div class="builder-sidebar">
      <h4>Thêm nội dung</h4>
      <%= link_to new_instructor_course_course_module_path(@course),
                  class: "add-item-btn" do %>
        <i class="bi bi-plus-circle"></i> Thêm Module
      <% end %>
    </div>

    <%# Main: Module tree %>
    <div class="builder-main"
         data-sortable-target="container"
         data-course-id="<%= @course.id %>">
      <% @modules.each do |mod| %>
        <div class="module-block"
             data-module-id="<%= mod.id %>"
             data-sortable-target="module">
          <div class="module-header">
            <div class="module-drag-handle">
              <i class="bi bi-grip-vertical"></i>
            </div>
            <h3 class="module-title"><%= mod.title %></h3>
            <div class="module-actions">
              <%= link_to edit_instructor_course_course_module_path(@course, mod),
                          class: "btn-icon", title: "Sửa" do %>
                <i class="bi bi-pencil"></i>
              <% end %>
              <%= button_to instructor_course_course_module_path(@course, mod),
                           method: :delete,
                           class: "btn-icon btn-icon--danger",
                           title: "Xóa",
                           data: { confirm: "Xóa module này?" } do %>
                <i class="bi bi-trash"></i>
              <% end %>
            </div>
          </div>

          <div class="lessons-list"
               data-sortable-target="lessonsContainer"
               data-module-id="<%= mod.id %>">
            <% mod.lessons.order(:order_index).each do |lesson| %>
              <div class="lesson-item"
                   data-lesson-id="<%= lesson.id %>"
                   data-sortable-target="lesson">
                <div class="lesson-drag-handle">
                  <i class="bi bi-grip-vertical"></i>
                </div>
                <div class="lesson-icon">
                  <% if lesson.video_url.present? %>
                    <i class="bi bi-play-circle"></i>
                  <% else %>
                    <i class="bi bi-file-text"></i>
                  <% end %>
                </div>
                <div class="lesson-info">
                  <span class="lesson-title"><%= lesson.title %></span>
                  <span class="lesson-meta">
                    <%= lesson.duration %> phút
                    <% if lesson.free_preview? %>
                      <span class="badge badge-info">Preview</span>
                    <% end %>
                  </span>
                </div>
                <div class="lesson-actions">
                  <%= link_to edit_instructor_course_lesson_path(@course, lesson),
                              class: "btn-icon" do %>
                    <i class="bi bi-pencil"></i>
                  <% end %>
                  <%= link_to new_instructor_course_lesson_path(@course, lesson, duplicate: lesson.id),
                              class: "btn-icon", title: "Nhân bản" do %>
                    <i class="bi bi-copy"></i>
                  <% end %>
                  <%= button_to instructor_course_lesson_path(@course, lesson),
                               method: :delete,
                               class: "btn-icon btn-icon--danger",
                               data: { confirm: "Xóa bài này?" } do %>
                    <i class="bi bi-trash"></i>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <%# Add lesson button inside module %>
          <%= link_to new_instructor_course_lesson_path(@course, mod),
                      class: "add-lesson-btn",
                      data: { module_id: mod.id } do %>
            <i class="bi bi-plus"></i> Thêm bài học
          <% end %>
        </div>
      <% end %>

      <% if @modules.empty? %>
        <div class="empty-state">
          <i class="bi bi-folder2-open"></i>
          <p>Chưa có module nào. Bắt đầu bằng cách thêm module đầu tiên.</p>
          <%= link_to "Thêm Module đầu tiên",
                      new_instructor_course_course_module_path(@course),
                      class: "btn btn-primary" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

#### 3.2.4 JavaScript Controller

```javascript
// app/javascript/controllers/course_builder_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import Rails from "@rails/ujs"

export default class extends Controller {
  static targets = ["container", "lessonsContainer"]

  connect() {
    this.initModuleSortable()
    this.initLessonSortable()
  }

  initModuleSortable() {
    Sortable.create(this.containerTarget, {
      animation: 200,
      handle: ".module-drag-handle",
      ghostClass: "sortable-ghost",
      onEnd: (event) => this.saveModuleOrder(event)
    })
  }

  initLessonSortable() {
    this.lessonsContainerTargets.forEach(container => {
      Sortable.create(container, {
        animation: 200,
        handle: ".lesson-drag-handle",
        group: "lessons",
        ghostClass: "sortable-ghost",
        onEnd: (event) => this.saveLessonOrder(event)
      })
    })
  }

  saveModuleOrder(event) {
    const order = Array.from(event.target.children)
      .filter(el => el.dataset.moduleId)
      .map(el => el.dataset.moduleId)

    Rails.ajax({
      type: "PATCH",
      url: `/instructor/courses/${this.containerTarget.dataset.courseId}/sort_modules`,
      data: new URLSearchParams({ module_order: order }).toString(),
      headers: { "Content-Type": "application/x-www-form-urlencoded" }
    })
  }

  saveLessonOrder(event) {
    // Collect lessons grouped by module
    const lessonOrder = []
    this.containerTarget.querySelectorAll(".module-block").forEach(mod => {
      mod.querySelectorAll(".lesson-item").forEach(lesson => {
        lessonOrder.push({
          id: lesson.dataset.lessonId,
          module_id: mod.dataset.moduleId
        })
      })
    })

    Rails.ajax({
      type: "PATCH",
      url: `/instructor/courses/${this.containerTarget.dataset.courseId}/sort_lessons`,
      data: new URLSearchParams({ lesson_order: lessonOrder }).toString(),
      headers: { "Content-Type": "application/x-www-form-urlencoded" }
    })
  }
}
```

#### 3.2.5 SCSS

```scss
// app/assets/stylesheets/pages/instructor/_course_builder.scss

.course-builder {
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;

    h1 { margin: 0; font-size: 1.5rem; }
  }

  &__actions {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  &__content {
    display: grid;
    grid-template-columns: 220px 1fr;
    gap: 1.5rem;

    @media (max-width: 768px) {
      grid-template-columns: 1fr;
    }
  }

  &__sidebar {
    h4 { margin-bottom: 1rem; color: var(--text-muted); font-size: 0.85rem; text-transform: uppercase; }
  }

  &__main {
    min-height: 400px;
  }
}

.module-block {
  background: white;
  border-radius: $radius-md;
  padding: 1.25rem;
  margin-bottom: 1rem;
  box-shadow: $shadow-sm;
  border: 2px solid transparent;
  transition: border-color 0.2s;

  &.sortable-ghost { border-color: var(--primary); opacity: 0.7; }

  &__header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1rem;
    padding-bottom: 0.75rem;
    border-bottom: 1px solid var(--border);
  }

  &__drag-handle {
    color: var(--text-muted);
    cursor: grab;
    padding: 0.25rem;
    &:active { cursor: grabbing; }
  }

  &__title {
    flex: 1;
    margin: 0;
    font-size: 1.1rem;
    font-weight: 600;
  }

  &__actions {
    display: flex;
    gap: 0.25rem;
  }
}

.lesson-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.6rem 0.75rem;
  border-radius: 6px;
  background: var(--bg);
  margin-bottom: 0.5rem;
  transition: background 0.15s;

  &:hover { background: darken($bg, 3%); }
  &.sortable-ghost { background: var(--primary-light); }

  &__drag-handle {
    color: var(--text-muted);
    cursor: grab;
    &:active { cursor: grabbing; }
  }

  &__icon { font-size: 1.2rem; color: var(--primary); }

  &__info {
    flex: 1;
    min-width: 0;
  }

  &__title {
    font-weight: 500;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  &__meta {
    font-size: 0.78rem;
    color: var(--text-muted);
  }

  &__actions {
    display: flex;
    gap: 0.25rem;
    opacity: 0;
    transition: opacity 0.15s;
  }

  &:hover &__actions { opacity: 1; }
}

.add-lesson-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  margin-top: 0.5rem;
  color: var(--text-muted);
  font-size: 0.85rem;
  border: 1px dashed var(--border);
  border-radius: 6px;
  text-decoration: none;
  transition: all 0.15s;

  &:hover {
    color: var(--primary);
    border-color: var(--primary);
    background: var(--primary-light);
  }
}
```

---

### I-3. Student Analytics Chi Tiết

**Effort:** 3 ngày
**Priority:** CAO
**Routes:** `instructor/courses/:id/students`

#### 3.3.1 Routes

```ruby
resources :courses do
  member do
    get :students          # Danh sach hoc vien
    get :student_analytics # Analytics cua 1 course
  end
end
```

#### 3.3.2 StudentAnalyticsController

```ruby
# app/controllers/instructor/student_analytics_controller.rb
class Instructor::StudentAnalyticsController < Instructor::BaseController
  before_action :set_course

  def show
    @enrollments = @course.enrollments
                           .includes(:user, :progress_trackings)
                           .order(created_at: :desc)

    @stats = {
      total_students: @enrollments.count,
      active_students: @enrollments.where(status: :active).count,
      completed_students: @course.progress_trackings.completed.distinct.count(:user_id),
      average_progress: calculate_avg_progress,
      average_quiz_score: calculate_avg_quiz_score
    }

    @enrollment_trend = @course.enrollments
                               .group_by_week(:created_at, range: 12.weeks.ago..Time.zone.now)
                               .count

    @completion_rate_chart = {
      "Hoàn thành" => @stats[:completed_students],
      "Đang học" => @stats[:active_students] - @stats[:completed_students],
      "Chưa học" => @stats[:total_students] - @stats[:active_students]
    }
  end

  private

  def set_course
    @course = current_user.courses.find(params[:course_id])
    authorize! :manage, @course
  end

  def calculate_avg_progress
    trackings = ProgressTracking.where(course_id: @course.id, status: :completed)
                                .group(:user_id).count
    return 0 if trackings.empty?

    module_count = @course.course_modules.count.to_f
    return 0 if module_count.zero?

    trackings.values.sum / (trackings.size * module_count) * 100
  end

  def calculate_avg_quiz_score
    attempts = QuizAttempt.where(quiz_id: @course.quizzes.pluck(:id))
                          .where(status: :completed)
                          .joins(:quiz)
                          .select("SUM(quiz_attempts.score * quizzes.weight) / SUM(quizzes.weight) as weighted_score")

    attempts.first&.weighted_score&.to_f&.round(1) || 0
  end
end
```

#### 3.3.3 View

```erb
<%# app/views/instructor/student_analytics/show.html.erb %>
<div class="student-analytics">
  <div class="page-header">
    <h1>Học viên khóa: <%= @course.title %></h1>
    <%= link_to instructor_course_path(@course), class: "btn btn-outline" do %>
      <i class="bi bi-arrow-left"></i> Quay lại
    <% end %>
  </div>

  <%# Stats Cards %>
  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-icon bg-blue"><i class="bi bi-people"></i></div>
      <div class="stat-content">
        <span class="stat-value"><%= @stats[:total_students] %></span>
        <span class="stat-label">Tổng học viên</span>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon bg-green"><i class="bi bi-check-circle"></i></div>
      <div class="stat-content">
        <span class="stat-value"><%= @stats[:completed_students] %></span>
        <span class="stat-label">Hoàn thành</span>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon bg-yellow"><i class="bi bi-graph-up"></i></div>
      <div class="stat-content">
        <span class="stat-value"><%= @stats[:average_progress] %>%</span>
        <span class="stat-label">Tiến độ TB</span>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon bg-purple"><i class="bi bi-trophy"></i></div>
      <div class="stat-content">
        <span class="stat-value"><%= @stats[:average_quiz_score] %></span>
        <span class="stat-label">Điểm quiz TB</span>
      </div>
    </div>
  </div>

  <%# Charts Row %>
  <div class="charts-row">
    <div class="chart-card">
      <h3>Xu hướng đăng ký (12 tuần)</h3>
      <%= line_chart @enrollment_trend,
            height: "250px",
            colors: ["#2563eb"],
            thousands: "." %>
    </div>
    <div class="chart-card">
      <h3>Tỷ lệ hoàn thành</h3>
      <%= pie_chart @completion_rate_chart,
            height: "250px",
            colors: ["#10b981", "#f59e0b", "#94a3b8"],
            legend: "bottom" %>
    </div>
  </div>

  <%# Student List %>
  <div class="students-table">
    <div class="table-header">
      <h3>Danh sách học viên (<%= @enrollments.total_count %>)</h3>
      <%= link_to "Export CSV", instructor_course_student_analytics_path(@course, format: :csv),
                  class: "btn btn-outline btn-sm" %>
    </div>

    <div class="table-responsive">
      <table class="data-table">
        <thead>
          <tr>
            <th>Học viên</th>
            <th>Ngày đăng ký</th>
            <th>Tiến độ</th>
            <th>Quiz</th>
            <th>Reviews</th>
            <th>Trạng thái</th>
          </tr>
        </thead>
        <tbody>
          <% @enrollments.each do |enrollment| %>
            <% user = enrollment.user %>
            <% progress = enrollment.progress_percent %>
            <tr>
              <td>
                <div class="user-cell">
                  <div class="user-avatar" style="background: #<%= Digest::MD5.hexdigest(user.email)[0..5] %>">
                    <%= user.name[0].upcase %>
                  </div>
                  <div>
                    <strong><%= user.name %></strong>
                    <span class="text-muted"><%= user.email %></span>
                  </div>
                </div>
              </td>
              <td><%= l enrollment.created_at, format: :short %></td>
              <td>
                <div class="progress-bar-cell">
                  <div class="progress-bar">
                    <div class="progress-bar__fill" style="width: <%= progress %>%"></div>
                  </div>
                  <span><%= progress %>%</span>
                </div>
              </td>
              <td>
                <% quiz_attempts = enrollment.user.quiz_attempts.where(quiz: @course.quizzes).completed %>
                <% if quiz_attempts.any? %>
                  <span class="badge badge-info">
                    <%= quiz_attempts.average(:score)&.round(1) || 0 %> / 10
                  </span>
                <% else %>
                  <span class="text-muted">—</span>
                <% end %>
              </td>
              <td>
                <% reviews = @course.reviews.where(user: user) %>
                <% if reviews.any? %>
                  <%= reviews.first.score %> ⭐
                <% else %>
                  <span class="text-muted">—</span>
                <% end %>
              </td>
              <td>
                <% if progress >= 100 %>
                  <span class="badge badge-success">Hoàn thành</span>
                <% elsif progress > 0 %>
                  <span class="badge badge-warning">Đang học</span>
                <% else %>
                  <span class="badge badge-secondary">Chưa học</span>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <div class="table-pagination">
      <%= paginate @enrollments %>
    </div>
  </div>
</div>
```

---

### I-4. Instructor Course Performance Page

**Effort:** 2 ngày
**Priority:** TRUNG BÌNH
**Routes:** `instructor/courses/performance`

#### 3.4.1 CoursePerformanceController

```ruby
class Instructor::CoursePerformanceController < Instructor::BaseController
  def index
    @courses = current_user.courses
                           .includes(:enrollments, :reviews)
                           .order(created_at: :desc)
  end

  def show
    @course = current_user.courses.find(params[:id])
    @monthly_revenue = @course.enrollments
                               .group_by_month(:created_at, range: 6.months.ago..Time.zone.now)
                               .sum("price * 0.7")

    @rating_distribution = @course.reviews.group(:score).count
    @enrollment_vs_completion = {
      "Đã enroll" => @course.enrollments.count,
      "Hoàn thành" => @course.progress_trackings.completed.distinct.count(:user_id)
    }
  end
end
```

#### 3.4.2 View

```erb
<%# app/views/instructor/course_performance/index.html.erb %>
<div class="course-performance">
  <h1>Hiệu suất khóa học</h1>

  <div class="courses-grid">
    <% @courses.each do |course| %>
      <div class="course-stat-card">
        <div class="course-stat-header">
          <h3><%= course.title %></h3>
          <span class="badge badge-<%= course.status %>"><%= course.status_text %></span>
        </div>
        <div class="course-stat-metrics">
          <div class="metric">
            <span class="metric-value"><%= course.enrollments.count %></span>
            <span class="metric-label">Học viên</span>
          </div>
          <div class="metric">
            <span class="metric-value"><%= course.reviews.count %></span>
            <span class="metric-label">Reviews</span>
          </div>
          <div class="metric">
            <span class="metric-value"><%= number_to_currency(course.revenue, unit: "", precision: 0) %>₫</span>
            <span class="metric-label">Doanh thu</span>
          </div>
          <div class="metric">
            <span class="metric-value"><%= number_with_precision(course.average_rating, precision: 1) %></span>
            <span class="metric-label">Rating</span>
          </div>
        </div>
        <div class="course-stat-chart">
          <%= column_chart course.monthly_enrollments,
                height: "120px",
                colors: ["#2563eb"] %>
        </div>
        <%= link_to "Chi tiết",
                    instructor_course_performance_path(course),
                    class: "btn btn-outline btn-block" %>
      </div>
    <% end %>
  </div>
</div>
```

---

### I-5. Coupon Analytics

**Effort:** 1 ngày
**Priority:** TRUNG BÌNH
**Routes:** `instructor/coupons`

#### 3.5.1 Coupon Enhancement

Thêm method vào `Coupon` model:

```ruby
class Coupon < ApplicationRecord
  # Existing scopes...

  def usage_count
    Enrollment.where("metadata LIKE ?", "%\"coupon_code\":\"#{code}\"%").count +
    Cart.where(promo_code: code).count
  end

  def total_discount_given
    Enrollment.joins(:course)
              .where("enrollments.metadata LIKE ?", "%\"coupon_code\":\"#{code}\"%")
              .sum("courses.price * #{discount_value / 100.0}")
  end

  def conversion_rate
    return 0 if views_count.zero?
    (usage_count.to_f / views_count * 100).round(1)
  end
end
```

#### 3.5.2 Enhanced Coupon Index View

```erb
<%# app/views/instructor/coupons/index.html.erb (nang cap) %>

<div class="coupon-analytics">
  <div class="page-header">
    <h1>Mã giảm giá</h1>
    <%= link_to "Tạo mã mới", new_instructor_coupon_path, class: "btn btn-primary" %>
  </div>

  <%# Coupon Stats %>
  <div class="coupon-stats">
    <div class="stat-card">
      <span class="stat-value"><%= @coupons.active.count %></span>
      <span class="stat-label">Mã đang hoạt động</span>
    </div>
    <div class="stat-card">
      <span class="stat-value"><%= @coupons.sum(&:usage_count) %></span>
      <span class="stat-label">Tổng lượt sử dụng</span>
    </div>
    <div class="stat-card">
      <span class="stat-value"><%= number_to_currency(@coupons.sum(&:total_discount_given), unit: "", precision: 0) %>₫</span>
      <span class="stat-label">Tổng giảm giá</span>
    </div>
  </div>

  <%# Coupons Table %>
  <table class="data-table">
    <thead>
      <tr>
        <th>Mã</th>
        <th>Loại</th>
        <th>Giá trị</th>
        <th>Lượt dùng</th>
        <th>Conversion</th>
        <th>Doanh thu tạo</th>
        <th>Hết hạn</th>
        <th>Thao tác</th>
      </tr>
    </thead>
    <tbody>
      <% @coupons.each do |coupon| %>
        <tr>
          <td><code><%= coupon.code %></code></td>
          <td><span class="badge"><%= coupon.discount_type_text %></span></td>
          <td><%= coupon.formatted_value %></td>
          <td><%= coupon.usage_count %></td>
          <td>
            <div class="conversion-bar">
              <div class="conversion-bar__fill" style="width: <%= coupon.conversion_rate %>%"></div>
            </div>
            <span><%= coupon.conversion_rate %>%</span>
          </td>
          <td><%= number_to_currency(coupon.revenue_generated, unit: "", precision: 0) %>₫</td>
          <td><%= l coupon.expires_at, format: :short if coupon.expires_at %></td>
          <td>
            <%= link_to "Sửa", edit_instructor_coupon_path(coupon), class: "btn-icon" %>
            <%= button_to instructor_coupon_path(coupon), method: :delete,
                          class: "btn-icon btn-icon--danger",
                          data: { confirm: "Xóa mã này?" } do %>
              <i class="bi bi-trash"></i>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

---

### I-6. Instructor Public Profile

**Effort:** 2 ngày
**Priority:** TRUNG BÌNH
**Routes:** `GET /instructors/:id`

#### 3.6.1 Routes

```ruby
# config/routes.rb
get "instructors/:id", to: "public_instructors#show", as: :public_instructor
```

#### 3.6.2 PublicInstructorsController

```ruby
class PublicInstructorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @instructor = User.instructor.find(params[:id])
    @courses = @instructor.courses.published
                          .includes(:reviews, :enrollments)
                          .order(created_at: :desc)

    @stats = {
      total_students: @courses.sum(&:enrollments_count),
      total_courses: @courses.count,
      avg_rating: @courses.average(:average_rating)&.round(1) || 0,
      total_reviews: @courses.sum { |c| c.reviews.count }
    }
  end
end
```

#### 3.6.3 View

```erb
<%# app/views/public_instructors/show.html.erb %>

<div class="instructor-profile">
  <div class="profile-header">
    <div class="profile-avatar">
      <%= @instructor.name[0].upcase %>
    </div>
    <div class="profile-info">
      <h1><%= @instructor.name %></h1>
      <% if @instructor.instructor_profile&.headline %>
        <p class="profile-headline"><%= @instructor.instructor_profile.headline %></p>
      <% end %>
      <div class="profile-stats">
        <div class="stat">
          <span class="stat-value"><%= @stats[:total_students] %></span>
          <span class="stat-label">Học viên</span>
        </div>
        <div class="stat">
          <span class="stat-value"><%= @stats[:total_courses] %></span>
          <span class="stat-label">Khóa học</span>
        </div>
        <div class="stat">
          <span class="stat-value"><%= @stats[:avg_rating] %></span>
          <span class="stat-label">Rating TB</span>
        </div>
      </div>
    </div>
  </div>

  <% if @instructor.instructor_profile&.bio.present? %>
    <div class="profile-bio">
      <h2>Giới thiệu</h2>
      <p><%= @instructor.instructor_profile.bio %></p>
    </div>
  <% end %>

  <div class="profile-courses">
    <h2>Khóa học (<%= @courses.count %>)</h2>
    <div class="courses-grid">
      <% @courses.each do |course| %>
        <%= render "courses/course_card", course: course %>
      <% end %>
    </div>
  </div>
</div>
```

---

## IV. B2B Module — Chi Tiết Từng Feature

### B-1. Enterprise Dashboard Nâng Cấp

**Effort:** 4 ngày
**Priority:** CAO
**Routes:** `business/dashboard`

#### 4.1.1 BusinessDashboardController Nâng Cấp

```ruby
class Business::DashboardController < Business::BaseController
  def index
    @organization = current_user.organization

    # License Stats
    @license_stats = {
      total: @organization.licenses.count,
      assigned: @organization.licenses.assigned.count,
      available: @organization.licenses.available.count,
      expiring_soon: @organization.licenses.expiring_soon.count,
      expired: @organization.licenses.expired.count
    }

    # Employee Progress Stats
    @employees = @organization.users.employees
                               .includes(:enrollments, :licenses)

    @employee_progress = {
      total: @employees.count,
      active: @employees.joins(:enrollments).distinct.count(:id),
      completed_courses: @employees.sum { |u| u.enrollments.where(status: :completed).count },
      in_progress: @employees.count - @employees.where(enrollments: { status: nil }).count
    }

    # Training ROI
    @total_spent = @organization.licenses.sum(:price).to_f
    @avg_completion_rate = calculate_avg_completion_rate
    @training_cost_per_employee = @total_spent / @employees.count rescue 0

    # Monthly enrollment trend
    @monthly_enrollments = Enrollment.joins(:course, :user)
                                     .where(users: { organization_id: @organization.id })
                                     .group_by_month(:created_at, range: 6.months.ago..Time.zone.now)
                                     .count

    # Top courses
    @top_courses = Course.joins(:licenses)
                         .where(licenses: { organization_id: @organization.id })
                         .group("courses.id")
                         .order("COUNT(licenses.id) DESC")
                         .limit(5)
  end

  private

  def calculate_avg_completion_rate
    return 0 if @employees.empty?

    total_progress = @employees.sum do |u|
      courses = u.enrollments.pluck(:course_id)
      next 0 if courses.empty?

      completed = ProgressTracking.where(user: u, status: :completed)
                                  .where(course_id: courses).distinct.count(:course_id)
      completed.to_f / courses.count * 100
    end

    (total_progress / @employees.count).round(1)
  end
end
```

#### 4.1.2 Enhanced View

```erb
<%# app/views/business/dashboard/index.html.erb %>

<div class="business-dashboard">
  <div class="page-header">
    <div>
      <h1><%= @organization.name %></h1>
      <span class="badge badge-<%= @organization.plan %>"><%= @organization.plan_text %></span>
    </div>
    <div class="header-actions">
      <%= link_to "Thêm nhân viên", new_business_employee_path, class: "btn btn-primary" %>
      <%= link_to "Mua license", business_course_market_path, class: "btn btn-outline" %>
    </div>
  </div>

  <%# License Overview %>
  <div class="section">
    <h2>License Overview</h2>
    <div class="stats-grid stats-grid--4">
      <div class="stat-card">
        <div class="stat-icon"><i class="bi bi-ticket-perforated"></i></div>
        <div class="stat-body">
          <span class="stat-value"><%= @license_stats[:total] %></span>
          <span class="stat-label">Tổng license</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--success"><i class="bi bi-check-circle"></i></div>
        <div class="stat-body">
          <span class="stat-value"><%= @license_stats[:assigned] %></span>
          <span class="stat-label">Đã gán</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--warning"><i class="bi bi-clock"></i></div>
        <div class="stat-body">
          <span class="stat-value"><%= @license_stats[:expiring_soon] %></span>
          <span class="stat-label">Sắp hết hạn</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--danger"><i class="bi bi-x-circle"></i></div>
        <div class="stat-body">
          <span class="stat-value"><%= @license_stats[:expired] %></span>
          <span class="stat-label">Đã hết hạn</span>
        </div>
      </div>
    </div>
  </div>

  <%# Employee Progress %>
  <div class="section">
    <h2>Tiến độ đào tạo</h2>
    <div class="stats-grid stats-grid--3">
      <div class="stat-card">
        <span class="stat-value"><%= @employee_progress[:total] %></span>
        <span class="stat-label">Tổng nhân viên</span>
      </div>
      <div class="stat-card">
        <span class="stat-value"><%= @avg_completion_rate %>%</span>
        <span class="stat-label">Tỷ lệ hoàn thành TB</span>
      </div>
      <div class="stat-card">
        <span class="stat-value"><%= number_to_currency(@training_cost_per_employee, unit: "", precision: 0) %>₫</span>
        <span class="stat-label">Chi phí/Nhân viên</span>
      </div>
    </div>

    <div class="chart-section">
      <div class="chart-card">
        <h3>Đăng ký khóa học theo tháng</h3>
        <%= line_chart @monthly_enrollments, height: "250px", colors: ["#0d9488"] %>
      </div>
    </div>
  </div>

  <%# Top Courses %>
  <div class="section">
    <h2>Khóa học phổ biến</h2>
    <table class="data-table">
      <thead>
        <tr>
          <th>Khóa học</th>
          <th>License đã gán</th>
          <th>Hoàn thành</th>
          <th>Tỷ lệ</th>
        </tr>
      </thead>
      <tbody>
        <% @top_courses.each do |course| %>
          <% licenses = @organization.licenses.where(course: course) %>
          <% assigned = licenses.assigned.count %>
          <% completed = licenses.joins(:user).where(users: { enrollments: { status: :completed } }).count %>
          <tr>
            <td><%= course.title %></td>
            <td><%= assigned %></td>
            <td><%= completed %></td>
            <td>
              <div class="progress-mini">
                <div class="progress-mini__fill" style="width: <%= assigned > 0 ? completed.to_f/assigned*100 : 0 %>%"></div>
              </div>
              <span><%= assigned > 0 ? (completed.to_f/assigned*100).round : 0 %>%</span>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

---

### B-2. Employee Progress Report Chi Tiết

**Effort:** 3 ngày
**Priority:** CAO
**Routes:** `business/employees/:id/progress`

#### 4.2.1 Routes

```ruby
namespace :business do
  resources :employees do
    member do
      get :progress     # Chi tiet tien do hoc tap
      get :export       # Export CSV
    end
  end
end
```

#### 4.2.2 EmployeeProgressController

```ruby
class Business::EmployeeProgressController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_company_admin!

  def show
    @employee = User.find(params[:employee_id])
    @organization = current_user.organization

    # Verify employee belongs to same org
    raise ActiveRecord::RecordNotFound unless @employee.organization_id == @organization.id

    @enrollments = @employee.enrollments
                             .includes(:course, :progress_trackings)
                             .order(created_at: :desc)

    @stats = {
      enrolled_courses: @enrollments.count,
      completed_courses: @enrollments.where(status: :completed).count,
      total_time_spent: @employee.progress_trackings.sum(:duration_seconds) / 3600,
      avg_score: @employee.quiz_attempts.completed.average(:score)&.round(1) || 0
    }

    @course_progress = @enrollments.map do |enrollment|
      course = enrollment.course
      completed_lessons = enrollment.progress_trackings.where(status: :completed).count
      total_lessons = course.lessons.count

      {
        course: course,
        enrollment: enrollment,
        progress_percent: total_lessons.positive? ? (completed_lessons.to_f / total_lessons * 100).round : 0,
        completed_lessons: completed_lessons,
        total_lessons: total_lessons,
        last_activity: enrollment.progress_trackings.order(updated_at: :desc).first&.updated_at
      }
    end
  end

  def export
    @employee = User.find(params[:employee_id])
    @organization = current_user.organization

    raise ActiveRecord::RecordNotFound unless @employee.organization_id == @organization.id

    respond_to do |format|
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"progress_#{@employee.name}.csv\""
      end
    end
  end

  private

  def ensure_company_admin!
    authorize! :access, :business_dashboard
  end
end
```

#### 4.2.2 View

```erb
<%# app/views/business/employee_progress/show.html.erb %>

<div class="employee-progress">
  <div class="page-header">
    <div class="breadcrumb">
      <%= link_to "Nhân viên", business_employees_path %> /
      <span><%= @employee.name %></span>
    </div>
    <div class="header-actions">
      <%= link_to "Export CSV",
                  export_business_employee_path(@employee, format: :csv),
                  class: "btn btn-outline" %>
    </div>
  </div>

  <%# Employee Overview %>
  <div class="employee-overview">
    <div class="employee-avatar">
      <%= @employee.name[0].upcase %>
    </div>
    <div class="employee-info">
      <h1><%= @employee.name %></h1>
      <p><%= @employee.email %></p>
      <% if @employee.profile&.department %>
        <span class="badge"><%= @employee.profile.department %></span>
      <% end %>
    </div>
    <div class="employee-stats">
      <div class="stat">
        <span class="stat-value"><%= @stats[:enrolled_courses] %></span>
        <span class="stat-label">Đã đăng ký</span>
      </div>
      <div class="stat">
        <span class="stat-value"><%= @stats[:completed_courses] %></span>
        <span class="stat-label">Hoàn thành</span>
      </div>
      <div class="stat">
        <span class="stat-value"><%= @stats[:total_time_spent] %>h</span>
        <span class="stat-label">Thời gian học</span>
      </div>
      <div class="stat">
        <span class="stat-value"><%= @stats[:avg_score] %></span>
        <span class="stat-label">Điểm quiz TB</span>
      </div>
    </div>
  </div>

  <%# Course Progress Table %>
  <div class="course-progress-section">
    <h2>Tiến độ khóa học</h2>
    <table class="data-table">
      <thead>
        <tr>
          <th>Khóa học</th>
          <th>Ngày đăng ký</th>
          <th>Tiến độ</th>
          <th>Bài học</th>
          <th>Quiz</th>
          <th>Hoạt động cuối</th>
          <th>Trạng thái</th>
        </tr>
      </thead>
      <tbody>
        <% @course_progress.each do |item| %>
          <tr>
            <td>
              <%= link_to item[:course].title, course_path(item[:course]) %>
            </td>
            <td><%= l item[:enrollment].created_at, format: :short %></td>
            <td>
              <div class="progress-cell">
                <div class="progress-bar">
                  <div class="progress-bar__fill" style="width: <%= item[:progress_percent] %>%"></div>
                </div>
                <span><%= item[:progress_percent] %>%</span>
              </div>
            </td>
            <td><%= item[:completed_lessons] %> / <%= item[:total_lessons] %></td>
            <td>
              <% quiz = item[:course].quizzes.first %>
              <% if quiz %>
                <% attempt = @employee.quiz_attempts.where(quiz: quiz).last %>
                <% if attempt %>
                  <span class="score"><%= attempt.score %> / 10</span>
                <% else %>
                  <span class="text-muted">Chưa làm</span>
                <% end %>
              <% else %>
                <span class="text-muted">—</span>
              <% end %>
            </td>
            <td>
              <% if item[:last_activity] %>
                <%= time_ago_in_words(item[:last_activity]) %> trước
              <% else %>
                <span class="text-muted">Chưa hoạt động</span>
              <% end %>
            </td>
            <td>
              <% if item[:progress_percent] >= 100 %>
                <span class="badge badge-success">Hoàn thành</span>
              <% elsif item[:progress_percent] > 0 %>
                <span class="badge badge-warning">Đang học</span>
              <% else %>
                <span class="badge badge-secondary">Chưa học</span>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

---

### B-3. Bulk CSV Import Employees

**Effort:** 2 ngày
**Priority:** CAO
**Routes:** `business/employees/import`

#### 4.3.1 Routes

```ruby
namespace :business do
  resources :employees do
    collection do
      get  :import_template  # Download CSV template
      post :bulk_import      # Process CSV
    end
  end
end
```

#### 4.3.2 Employee Import Service

```ruby
# app/services/employee_import_service.rb
class EmployeeImportService
  attr_reader :organization, :csv_data, :current_user

  def initialize(organization, csv_data, current_user)
    @organization = organization
    @csv_data = csv_data
    @current_user = current_user
    @results = { imported: [], failed: [] }
  end

  def call
    CSV.parse(csv_data, headers: true, col_sep: ",").each do |row|
      import_row(row)
    end
    @results
  end

  private

  def import_row(row)
    email = row["email"]&.strip
    name = row["name"]&.strip
    phone = row["phone"]&.strip
    department = row["department"]&.strip

    # Validation
    if email.blank?
      @results[:failed] << { email: email, error: "Email không được để trống" }
      return
    end

    if User.exists?(email: email)
      @results[:failed] << { email: email, error: "Email đã tồn tại trong hệ thống" }
      return
    end

    # Create user
    user = User.create!(
      email: email,
      name: name || email.split("@").first,
      phone: phone,
      password: SecureRandom.hex(8),
      role: :employee,
      organization_id: @organization.id,
      confirmed_at: Time.current  # Auto-confirm for bulk import
    )

    # Create profile if department provided
    if department.present?
      user.build_profile(department: department)
      user.profile.save
    end

    @results[:imported] << { email: email, user_id: user.id }

    # Send invitation email
    UserMailer.bulk_employee_invitation(user, current_user).deliver_later
  rescue => e
    @results[:failed] << { email: email, error: e.message }
  end
end
```

#### 4.3.3 BulkImportController

```ruby
class Business::BulkImportsController < Business::BaseController
  def new
    @import = BulkImport.new
  end

  def create
    file = params[:bulk_import][:file]

    unless file.present? && file.content_type == "text/csv"
      redirect_to new_business_bulk_import_path, alert: "Vui lòng upload file CSV"
      return
    end

    service = EmployeeImportService.new(
      current_user.organization,
      file.read.force_encoding("UTF-8"),
      current_user
    )

    @results = service.call

    if @results[:imported].any?
      redirect_to business_employees_path,
                  notice: "Đã import #{@results[:imported].count} nhân viên thành công" +
                          (@results[:failed].any? ? ". #{@results[:failed].count} thất bại." : ".")
    else
      redirect_to new_business_bulk_import_path,
                  alert: "Import thất bại. Vui lòng kiểm tra file CSV."
    end
  end

  def template
    csv_data = "email,name,phone,department\n"
    csv_data += "nguyenvana@company.com,Nguyen Van A,0901234567,Engineering\n"
    csv_data += "tranvanb@company.com,Tran Van B,0902345678,Marketing\n"

    send_data csv_data, filename: "employee_import_template.csv", type: "text/csv"
  end
end
```

#### 4.3.4 View

```erb
<%# app/views/business/bulk_imports/new.html.erb %>

<div class="bulk-import">
  <h1>Import nhân viên hàng loạt</h1>

  <div class="import-info">
    <h3>Hướng dẫn</h3>
    <ol>
      <li>Tải template CSV bên dưới</li>
      <li>Điền thông tin nhân viên vào file (email bắt buộc, các trường khác tùy chọn)</li>
      <li>Upload file đã điền</li>
      <li>Email sẽ được gửi tự động cho mỗi nhân viên mới</li>
    </ol>
    <%= link_to "Tải template CSV",
                import_template_business_bulk_imports_path,
                class: "btn btn-outline" %>
  </div>

  <div class="import-form">
    <h3>Upload file</h3>
    <%= form_with model: @import, url: business_bulk_imports_path,
                  local: true, html: { multipart: true } do |f| %>
      <div class="form-group">
        <%= f.label :file, "Chọn file CSV" %>
        <%= f.file_field :file, accept: ".csv", required: true %>
      </div>
      <%= f.submit "Import", class: "btn btn-primary" %>
    <% end %>
  </div>
</div>
```

#### 4.3.5 SCSS

```scss
// app/assets/stylesheets/pages/business/_bulk_import.scss

.bulk-import {
  max-width: 800px;
  margin: 0 auto;

  .import-info {
    background: white;
    padding: 1.5rem;
    border-radius: $radius-md;
    margin-bottom: 1.5rem;

    h3 { margin-bottom: 1rem; }

    ol {
      margin-bottom: 1.5rem;
      padding-left: 1.5rem;

      li { margin-bottom: 0.5rem; }
    }
  }

  .import-form {
    background: white;
    padding: 1.5rem;
    border-radius: $radius-md;

    h3 { margin-bottom: 1.5rem; }

    .form-group {
      margin-bottom: 1.5rem;

      label {
        display: block;
        font-weight: 500;
        margin-bottom: 0.5rem;
      }

      input[type="file"] {
        padding: 0.5rem;
        border: 1px solid var(--border);
        border-radius: 6px;
        width: 100%;
      }
    }
  }
}
```

---

### B-4. License Expiration Tracking

**Effort:** 1 ngày
**Priority:** TRUNG BÌNH
**Database:** Migration

#### 4.4.1 Migration

```bash
rails g migration AddExpiresAtToLicenses expires_at:datetime
```

#### 4.4.2 License Model Enhancement

```ruby
class License < ApplicationRecord
  belongs_to :organization
  belongs_to :course
  belongs_to :user, optional: true

  enum status: { available: 0, assigned: 1, expired: 2 }

  # Scopes
  scope :expiring_soon, -> {
    where("expires_at IS NOT NULL AND expires_at <= ? AND expires_at > ?", 7.days.from_now, Time.current)
      .where.not(status: :expired)
  }

  scope :expired_now, -> {
    where("expires_at IS NOT NULL AND expires_at <= ?", Time.current)
      .where.not(status: :expired)
  }

  # Auto-expire job (run daily)
  def self.expire_licenses!
    expired_now.find_each do |license|
      license.update!(status: :expired)
      LicenseExpirationJob.perform_later(license) if license.user_id?
    end
  end

  # Check if expired (memoized)
  def expired?
    return false unless expires_at.present?
    expires_at <= Time.current || status == :expired
  end
end
```

#### 4.4.3 Sidekiq Job

```ruby
# app/jobs/license_expiration_job.rb
class LicenseExpirationJob < ApplicationJob
  queue_as :default

  def perform(license)
    user = license.user
    organization = license.organization

    # Notify employee
    Notification.create!(
      user: user,
      title: "License hết hạn",
      body: "License khóa '#{license.course.title}' đã hết hạn.",
      notification_type: :license_expired,
      actionable: license
    )

    # Notify company admin
    admins = organization.users.company_admin
    admins.each do |admin|
      Notification.create!(
        user: admin,
        title: "Nhân viên mất license",
        body: "#{user.name} đã hết license khóa '#{license.course.title}'.",
        notification_type: :license_expired,
        actionable: license
      )
    end
  end
end
```

#### 4.4.4 Schedule Daily Job

```ruby
# config/sidekiq.yml hoặc initializer
# config/initializers/sidekiq.rb
Sidekiq::Cron::Job.create(
  name: "Expire licenses daily",
  cron: "0 0 * * *",
  class: "LicenseExpirationJob"
)
```

#### 4.4.5 Enhanced License Index View

```erb
<%# app/views/business/licenses/index.html.erb (nang cap) %>

<div class="licenses-page">
  <div class="page-header">
    <h1>Quản lý License</h1>
    <div class="header-actions">
      <% if @expiring_count > 0 %>
        <div class="alert alert-warning">
          <i class="bi bi-exclamation-triangle"></i>
          <%= @expiring_count %> license sắp hết hạn trong 7 ngày
        </div>
      <% end %>
      <%= link_to "Mua thêm license", business_course_market_path, class: "btn btn-primary" %>
    </div>
  </div>

  <%# Tabs %>
  <ul class="license-tabs">
    <li class="<%= "active" if params[:tab] != "expired" %>">
      <%= link_to "Đang hoạt động (#{@active_count})",
                  business_licenses_path(tab: "active") %>
    </li>
    <li class="<%= "active" if params[:tab] == "expired" %>">
      <%= link_to "Đã hết hạn (#{@expired_count})",
                  business_licenses_path(tab: "expired") %>
    </li>
  </ul>

  <table class="data-table">
    <thead>
      <tr>
        <th>Khóa học</th>
        <th>Mã License</th>
        <th>Người dùng</th>
        <th>Ngày mua</th>
        <th>Hết hạn</th>
        <th>Trạng thái</th>
        <th>Thao tác</th>
      </tr>
    </thead>
    <tbody>
      <% @licenses.each do |license| %>
        <tr class="<%= "warning-row" if license.expires_at && license.expires_at < 7.days.from_now %>">
          <td><%= link_to license.course.title, course_path(license.course) %></td>
          <td><code><%= license.code %></code></td>
          <td>
            <% if license.user %>
              <%= link_to license.user.name, progress_business_employee_path(license.user) %>
            <% else %>
              <span class="text-muted">Chưa gán</span>
            <% end %>
          </td>
          <td><%= l license.created_at, format: :short %></td>
          <td>
            <% if license.expires_at %>
              <%= l license.expires_at, format: :short %>
              <% if license.expires_at < 7.days.from_now && license.expires_at > Time.current %>
                <span class="badge badge-warning">Sắp hết</span>
              <% end %>
            <% else %>
              <span class="text-muted">Không giới hạn</span>
            <% end %>
          </td>
          <td>
            <% if license.status == "assigned" %>
              <span class="badge badge-success">Đã gán</span>
            <% elsif license.status == "available" %>
              <span class="badge badge-info">Khả dụng</span>
            <% else %>
              <span class="badge badge-secondary">Đã hết hạn</span>
            <% end %>
          </td>
          <td>
            <% if license.available? %>
              <%= link_to "Gán cho nhân viên",
                          assign_business_licenses_path(license_id: license.id),
                          class: "btn btn-sm btn-outline",
                          data: { turbo_frame: "assign_modal" } %>
            <% elsif license.assigned? && license.expires_at.nil? %>
              <%= button_to "Thu hồi",
                            revoke_business_license_path(license),
                            method: :patch,
                            class: "btn btn-sm btn-outline-danger",
                            data: { confirm: "Thu hồi license?" } %>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

---

### B-5. Custom Learning Path Cho Tổ Chức

**Effort:** 5 ngày
**Priority:** THẤP (Nếu cần)
**Models:** OrganizationLearningPath, PathAssignment

#### 4.5.1 Models

```ruby
# app/models/organization_learning_path.rb
class OrganizationLearningPath < ApplicationRecord
  belongs_to :organization
  belongs_to :creator, class_name: "User"

  has_many :path_assignments, dependent: :destroy
  has_many :employees, through: :path_assignments, source: :user

  validates :title, presence: true
  validates :course_ids, presence: true

  serialize :course_ids, Array

  def courses
    Course.where(id: course_ids).order("FIELD(id, #{course_ids.join(',')})")
  end

  def total_courses
    course_ids.count
  end
end

# app/models/path_assignment.rb
class PathAssignment < ApplicationRecord
  belongs_to :organization_learning_path
  belongs_to :user

  validates :user_id, uniqueness: { scope: :organization_learning_path_id }

  scope :in_progress, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  def progress_percent
    return 0 if organization_learning_path.total_courses.zero?

    completed_courses = ProgressTracking.where(user: user)
                                        .where(course_id: organization_learning_path.course_ids)
                                        .group(:course_id).count.keys.count

    (completed_courses.to_f / organization_learning_path.total_courses * 100).round
  end
end
```

#### 4.5.2 Routes

```ruby
namespace :business do
  resources :learning_paths do
    member do
      post :assign_employees
    end
    resources :assignments, only: [] do
      member do
        patch :complete
      end
    end
  end
end
```

#### 4.5.3 Views

```erb
<%# app/views/business/learning_paths/index.html.erb %>

<div class="learning-paths">
  <div class="page-header">
    <h1>Lộ trình đào tạo</h1>
    <%= link_to "Tạo lộ trình mới",
                new_business_learning_path_path,
                class: "btn btn-primary" %>
  </div>

  <div class="paths-list">
    <% @paths.each do |path| %>
      <div class="path-card">
        <div class="path-header">
          <h3><%= path.title %></h3>
          <span class="badge"><%= path.total_courses %> khóa</span>
        </div>
        <p><%= path.description %></p>
        <div class="path-meta">
          <span><%= path.employees.count %> nhân viên được gán</span>
          <span><%= path.path_assignments.completed.count %> đã hoàn thành</span>
        </div>
        <div class="path-courses">
          <% path.courses.first(3).each do |course| %>
            <div class="mini-course-card">
              <i class="bi bi-play-circle"></i>
              <span><%= course.title %></span>
            </div>
          <% end %>
          <% if path.courses.count > 3 %>
            <span class="more-courses">+<%= path.courses.count - 3 %> khóa khác</span>
          <% end %>
        </div>
        <div class="path-actions">
          <%= link_to "Gán nhân viên",
                      assign_employees_business_learning_path_path(path),
                      class: "btn btn-sm btn-outline" %>
          <%= link_to "Xem chi tiết",
                      business_learning_path_path(path),
                      class: "btn btn-sm btn-outline" %>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

---

### B-6. Organization Branding Settings

**Effort:** 2 ngày
**Priority:** THẤP
**Models:** OrganizationSetting

#### 4.6.1 Model

```ruby
# app/models/organization_setting.rb
class OrganizationSetting < ApplicationRecord
  belongs_to :organization

  validates :organization_id, uniqueness: true

  # Default values
  PRIMARY_COLOR = "#2563eb"
  SECONDARY_COLOR = "#0d9488"

  def primary_color
    super || PRIMARY_COLOR
  end

  def secondary_color
    super || SECONDARY_COLOR
  end
end
```

#### 4.6.2 Migration

```bash
rails g model OrganizationSetting organization:belongs_to primary_color:string secondary_color:string logo_url:string
```

#### 4.6.3 Organization Settings Controller

```ruby
class Business::OrganizationSettingsController < Business::BaseController
  def edit
    @setting = current_user.organization.build_setting
  end

  def update
    @setting = current_user.organization.setting || current_user.organization.build_setting
    if @setting.update(setting_params)
      redirect_to edit_business_organization_setting_path,
                  notice: "Đã lưu cài đặt thương hiệu"
    else
      render :edit
    end
  end

  private

  def setting_params
    params.require(:organization_setting).permit(:primary_color, :secondary_color, :logo)
  end
end
```

---

## V. Cross-Cutting Features (Chung)

### X-1. SCSS Design System Chung

```scss
// app/assets/stylesheets/pages/instructor/_shared_instructor.scss
// Dùng chung cho instructor namespace

.instructor-page {
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;

    h1 { margin: 0; }
  }

  &__actions {
    display: flex;
    gap: 0.75rem;
  }
}

.stats-grid {
  display: grid;
  gap: 1.5rem;
  margin-bottom: 2rem;

  &--2 { grid-template-columns: repeat(2, 1fr); }
  &--3 { grid-template-columns: repeat(3, 1fr); }
  &--4 { grid-template-columns: repeat(4, 1fr); }

  @media (max-width: 1024px) { grid-template-columns: repeat(2, 1fr); }
  @media (max-width: 640px) { grid-template-columns: 1fr; }
}

.stat-card {
  background: white;
  border-radius: $radius-md;
  padding: 1.25rem;
  box-shadow: $shadow-sm;
  display: flex;
  align-items: center;
  gap: 1rem;

  &__icon {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.25rem;
    flex-shrink: 0;

    &.bg-blue { background: rgba(37, 99, 235, 0.1); color: $primary; }
    &.bg-green { background: rgba(16, 185, 129, 0.1); color: $success; }
    &.bg-yellow { background: rgba(245, 158, 11, 0.1); color: $warning; }
    &.bg-purple { background: rgba(139, 92, 246, 0.1); color: #8b5cf6; }
    &.bg-red { background: rgba(239, 68, 68, 0.1); color: $danger; }
  }

  &__content { flex: 1; }

  &__value {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--text-dark);
    line-height: 1.2;
  }

  &__label {
    font-size: 0.8rem;
    color: var(--text-muted);
  }
}

.data-table {
  width: 100%;
  background: white;
  border-radius: $radius-md;
  overflow: hidden;
  box-shadow: $shadow-sm;

  th, td { padding: 0.75rem 1rem; text-align: left; }
  th {
    background: var(--bg);
    font-weight: 600;
    font-size: 0.8rem;
    text-transform: uppercase;
    color: var(--text-muted);
  }
  tr { border-bottom: 1px solid var(--border); }
  tr:last-child { border-bottom: none; }
  tr:hover { background: var(--bg); }
}

.progress-bar {
  height: 6px;
  background: var(--border);
  border-radius: 3px;
  overflow: hidden;

  &__fill {
    height: 100%;
    background: $primary;
    border-radius: 3px;
    transition: width 0.3s ease;
  }
}

.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;

  &-success { background: rgba(16, 185, 129, 0.1); color: $success; }
  &-warning { background: rgba(245, 158, 11, 0.1); color: $warning; }
  &-danger { background: rgba(239, 68, 68, 0.1); color: $danger; }
  &-info { background: rgba(37, 99, 235, 0.1); color: $primary; }
  &-secondary { background: var(--bg); color: var(--text-muted); }
}
```

---

## VI. Thứ Tự Triển Khai

```
GIAI ĐOẠN 1: Instructor Dashboard (Tuần 1-2)
═══════════════════════════════════════════════
[I-1] KPI Cards + Revenue Chart Nâng Cấp    ☐ 2 ngày
[I-2] Course Builder Drag-Drop              ☐ 5 ngày

GIAI ĐOẠN 2: Instructor Analytics (Tuần 3)
═══════════════════════════════════════════════
[I-3] Student Analytics Chi Tiết              ☐ 3 ngày
[I-4] Course Performance Page                ☐ 2 ngày
[I-5] Coupon Analytics                       ☐ 1 ngày
[I-6] Instructor Public Profile              ☐ 2 ngày

GIAI ĐOẠN 3: B2B Module (Tuần 4-5)
═══════════════════════════════════════════════
[B-1] Enterprise Dashboard Nâng Cấp          ☐ 4 ngày
[B-2] Employee Progress Report               ☐ 3 ngày
[B-3] Bulk CSV Import Employees               ☐ 2 ngày
[B-4] License Expiration Tracking            ☐ 1 ngày

GIAI ĐOẠN 4: B2B Nâng Cao (Tuần 6-7)
═══════════════════════════════════════════════
[B-5] Custom Learning Path                   ☐ 5 ngày (optional)
[B-6] Organization Branding                  ☐ 2 ngày (optional)
```

---

## VII. Dependencies & Prerequisites

### Models can phai ton tai
- ✅ `User` (co `organization_id`, `role`)
- ✅ `Course` (co `creator_id`, `status`)
- ✅ `Enrollment` (co `user_id`, `course_id`, `status`)
- ✅ `ProgressTracking` (co `user_id`, `course_id`, `status`)
- ✅ `License` (can them `expires_at`)
- ✅ `Coupon`
- ✅ `Organization`

### Gems can thêm
```ruby
# Gemfile
gem "sortablejs-rails"  # Drag-drop
gem "chartkick"         # Da co
gem "groupdate"         # Da co
```

### JavaScript libraries
```javascript
// app/javascript/application.js
@import "sortablejs"
```

---

## VIII. Checklist

### Trước khi bắt đầu
- [ ] Review và approve plan này
- [ ] Xác định thứ tự ưu tiên (có thể bỏ qua B5, B6 nếu không cần)
- [ ] Setup SortableJS trong importmap

### Sau khi triển khai mỗi feature
- [ ] Viết tests cho controller/service mới
- [ ] Thêm i18n strings
- [ ] Check N+1 queries
- [ ] Test trên mobile
- [ ] Review RuboCop

---

*Kế hoạch này tập trung hoàn toàn vào Instructor Module và B2B Module. Các phần khác (technical debt, AI features, security) sẽ được triển khai trong plan riêng.*
