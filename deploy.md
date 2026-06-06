---
name: Triển khai Rails E-Learning lên Production (Render.com)
overview: Kế hoạch chi tiết để triển khai hệ thống Rails E-Learning lên production với PostgreSQL và các dịch vụ free tier trên Render.com (web + PostgreSQL + Redis).
todos:
  - id: step1_render
    content: "Bước 1.1: Tạo tài khoản Render.com"
    status: pending
  - id: step1_psql
    content: "Bước 1.2: Tạo PostgreSQL Database trên Render"
    status: pending
  - id: step1_redis
    content: "Bước 1.3: Tạo Redis trên Render"
    status: pending
  - id: step1_sendgrid
    content: "Bước 1.4: Tạo tài khoản SendGrid"
    status: pending
  - id: step1_sentry
    content: "Bước 1.5: Tạo tài khoản Sentry"
    status: pending
  - id: migrate_db
    content: "Bước 2: Migrate từ MySQL sang PostgreSQL"
    status: pending
  - id: security
    content: "Bước 3: Làm sạch security trong database.yml và initializers"
    status: pending
  - id: env_example
    content: "Bước 4: Tạo file .env.example"
    status: pending
  - id: prod_env
    content: "Bước 5: Cập nhật config/environments/production.rb"
    status: pending
  - id: puma
    content: "Bước 6: Tạo config/puma.rb"
    status: pending
  - id: render_config
    content: "Bước 7: Tạo Procfile + render.yaml"
    status: pending
  - id: sentry
    content: "Bước 8: Cấu hình Sentry"
    status: pending
  - id: ci_cd
    content: "Bước 9: Cập nhật GitHub Actions"
    status: pending
isProject: false
---

# Kế hoạch: Triển khai Rails E-Learning lên Production

---

## Bước 1: Tạo tài khoản dịch vụ (Người dùng tự làm)

---

### Bước 1.1: Tạo tài khoản Render.com

**Truy cập:** [render.com](https://render.com)

#### 1.1.1: Đăng ký

1. Mở trình duyệt, truy cập [render.com](https://render.com)
2. Click **"Get Started"** hoặc **"Sign Up"**
3. Chọn **"GitHub"** để đăng nhập (nhanh nhất, không cần nhớ password)
4. Cho phép Render truy cập GitHub (chọn repo `dn-ruby-naitei-2025_e-learning-system`)
5. Hoàn tất đăng ký với email/password

#### 1.1.2: Lấy Render API Key

1. Sau khi đăng nhập, vào **Dashboard**
2. Click **Avatar** (góc trên phải) -> **My Account** (hoặc **Account Settings**)
3. Chọn tab **API Keys**
4. Click **Create API Key**
5. Đặt tên: `rails-elearning-deploy`
6. Copy API Key và **lưu lại** (sẽ dùng cho GitHub Actions)

#### 1.1.3: Thêm Render API Key vào GitHub

1. Truy cập **GitHub repo**: `dn-ruby-naitei-2025_e-learning-system`
2. Vào **Settings** -> **Secrets and variables** -> **Actions**
3. Click **New repository secret**
4. Name: `RENDER_API_KEY`
5. Secret: paste API Key từ Render
6. Click **Add secret**

---

### Bước 1.2: Tạo PostgreSQL Database trên Render

1. Trên Render Dashboard, click **"New +"** (góc trên phải)
2. Chọn **"PostgreSQL"**
3. Điền thông tin:


| Field             | Value                   |
| ----------------- | ----------------------- |
| **Name**          | `rails-elearning-db`    |
| **Database Name** | `rails_e_learning_prod` |
| **Region**        | `Singapore`             |
| **Instance Type** | `Free`                  |


1. Click **Create Database**
2. **Đợi** khoảng 2-3 phút cho database được tạo
3. Khi xong, copy **Connection String** (Internal Database URL):

```
   postgresql://username:password@host:5432/database


```

1. **Lưu lại** connection string này

---

### Bước 1.3: Tạo Redis trên Render

1. Trên Render Dashboard, click **"New +"**
2. Chọn **"Redis"**
3. Điền thông tin:


| Field             | Value                   |
| ----------------- | ----------------------- |
| **Name**          | `rails-elearning-redis` |
| **Region**        | `Singapore`             |
| **Instance Type** | `Free`                  |


1. Click **Create Redis**
2. **Đợi** khoảng 1-2 phút
3. Copy **Connection String** (Internal Redis URL):

```
   redis://host:6379


```

---

### Bước 1.4: Tạo tài khoản SendGrid

**Truy cập:** [sendgrid.com](https://sendgrid.com)

#### 1.4.1: Đăng ký

1. Truy cập [sendgrid.com](https://sendgrid.com)
2. Click **"Start for Free"**
3. Điền thông tin:
  - Email (dùng email thật vì cần verify)
  - Password
  - Full name
4. Verify email qua link gửi về inbox
5. Đăng nhập vào SendGrid Dashboard

#### 1.4.2: Tạo API Key

1. Trong SendGrid Dashboard, vào **Settings** -> **API Keys**
2. Click **Create API Key**
3. Chọn **Full Access** hoặc **Restricted Access** (chỉ cần Mail Send)
4. Đặt tên: `rails-elearning`
5. Click **Create & View**
6. **COPY NGAY** API Key (chỉ hiển thị 1 lần duy nhất)
7. **Lưu lại** API Key

#### 1.4.3: Verify Sender (Required!)

1. Vào **Settings** -> **Sender Authentication**
2. Click **Verify a Single Sender** (hoặc **Domain Authentication**)
3. Điền thông tin:


| Field          | Value                     |
| -------------- | ------------------------- |
| **From Email** | `noreply@your-domain.com` |
| **From Name**  | `E-Learning System`       |
| **Reply To**   | `noreply@your-domain.com` |


1. Click **Create**
2. Check email inbox -> click link verify
3. **Lưu lại** email đã verify (sẽ dùng làm `MAIL_FROM_ADDRESS`)

---

### Bước 1.5: Tạo tài khoản Sentry

**Truy cập:** [sentry.io](https://sentry.io)

#### 1.5.1: Đăng ký

1. Truy cập [sentry.io](https://sentry.io)
2. Click **Sign Up**
3. Đăng nhập bằng **GitHub** (nhanh nhất)
4. Cấp quyền cho Sentry truy cập GitHub
5. Hoàn tất đăng ký

#### 1.5.2: Tạo Project

1. Sau khi đăng nhập, click **"Create Project"**
2. Chọn framework: **Ruby on Rails**
3. Đặt tên project: `rails-elearning`
4. Click **Create Project**

#### 1.5.3: Lấy DSN

1. Vào **Project Settings** (Settings icon)
2. Chọn tab **Client Keys (DSN)**
3. Copy **DSN**:

```
   https://xxxxx@sentry.io/xxxxx


```

1. **Lưu lại** DSN này

---

### Checklist Bước 1

Sau khi hoàn thành, bạn cần có:

- **Render API Key** (đã thêm vào GitHub Secrets)
- **PostgreSQL Connection String** từ Render
- **Redis Connection String** từ Render
- **SendGrid API Key**
- **SendGrid Verified Sender Email**
- **Sentry DSN**

---

## Bước 2: Migrate từ MySQL sang PostgreSQL

### 2.1. Thay đổi Gemfile

```ruby
# Gemfile
gem "pg", "~> 1.5"

# Xóa dòng này
# gem "mysql2", "~> 0.5"
```

### 2.2. Cập nhật `config/database.yml`

```ruby
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV["DB_USERNAME"] %>
  password: <%= ENV["DB_PASSWORD"] %>
  host: <%= ENV["DB_HOST"] %>
  port: <%= ENV.fetch("DB_PORT", 5432) %>

development:
  <<: *default
  database: rails_e_learning_development

test:
  <<: *default
  database: rails_e_learning_test

production:
  <<: *default
  database: <%= ENV["DB_NAME"] || "rails_e_learning_production" %>
  url: <%= ENV["DATABASE_URL"] %>
```

### 2.3. Sửa query không tương thích


| MySQL                        | PostgreSQL                      |
| ---------------------------- | ------------------------------- |
| `IFNULL(x, 0)`               | `COALESCE(x, 0)`                |
| `LIMIT 10, 20`               | `LIMIT 10 OFFSET 20`            |
| `NOW() + INTERVAL 7 DAY`     | `NOW() + INTERVAL '7 days'`     |
| `YEAR(created_at)`           | `EXTRACT(YEAR FROM created_at)` |
| `GROUP_CONCAT(x)`            | `STRING_AGG(x, ',')`            |
| `DATE_FORMAT(d, '%Y-%m-%d')` | `TO_CHAR(d, 'YYYY-MM-DD')`      |


---

## Bước 3: Làm sạch Security

```bash
# Tìm credentials hardcoded
grep -rn "22032004" .
grep -rn "password.*2203" .
```

---

## Bước 4: Tạo `.env.example`

```
RAILS_ENV=production
RAILS_MASTER_KEY=your_rails_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here

# Database (tự động từ render.yaml)
DATABASE_URL=postgresql://user:password@host/db

# Cloudinary (đã có)
CLOUDINARY_CLOUD_NAME=xxx
CLOUDINARY_API_KEY=xxx
CLOUDINARY_API_SECRET=xxx

# Stripe (đã có)
STRIPE_PUBLISHABLE_KEY=pk_live_xxx
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# YouTube (đã có)
YOUTUBE_API_KEY=xxx

# Redis (tự động từ render.yaml)
REDIS_URL=redis://host:6379

# Email (SendGrid)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=xxx
MAIL_FROM_ADDRESS=noreply@domain.com

# App
APP_HOST=your-app.onrender.com

# Sentry
SENTRY_DSN=https://xxx@sentry.io/xxx
```

---

## Bước 5: Cập nhật `production.rb`

```ruby
# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.compile = false
  config.assets.digest = true

  config.active_storage.service = :cloudinary

  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379"),
    expires_in: 90.minutes
  }

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_HOST"],
    port: ENV["SMTP_PORT"] || 587,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    domain: ENV["SMTP_DOMAIN"],
    authentication: :login,
    enable_starttls_auto: true
  }
  config.action_mailer.default_options = {
    from: ENV["MAIL_FROM_ADDRESS"] || "noreply@example.com"
  }
  config.action_mailer.default_url_options = {
    host: ENV["APP_HOST"] || "your-app.onrender.com",
    protocol: "https"
  }

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false
end
```

---

## Bước 6: Tạo `config/puma.rb`

```ruby
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "production") == "production"
preload_app!

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "production")

plugin :tmp_restart
```

---

## Bước 7: Tạo config Render

### `Procfile`

```
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
```

### `render.yaml`

```yaml
services:
  - type: web
    name: rails-elearning
    env: ruby
    region: singapore
    plan: free
    buildCommand: bundle install && bundle exec rails assets:precompile
    startCommand: bundle exec puma -C config/puma.rb
    healthCheckPath: /health
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_MASTER_KEY
        sync: false
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: DATABASE_URL
        fromDatabase:
          name: rails-elearning-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          type: redis
          name: rails-elearning-redis
          envVarKey: REDIS_URL
      - key: CLOUDINARY_CLOUD_NAME
        sync: false
      - key: CLOUDINARY_API_KEY
        sync: false
      - key: CLOUDINARY_API_SECRET
        sync: false
      - key: STRIPE_PUBLISHABLE_KEY
        sync: false
      - key: STRIPE_SECRET_KEY
        sync: false
      - key: STRIPE_WEBHOOK_SECRET
        sync: false
      - key: YOUTUBE_API_KEY
        sync: false
      - key: SMTP_HOST
        value: smtp.sendgrid.net
      - key: SMTP_PORT
        value: "587"
      - key: SMTP_USERNAME
        value: apikey
      - key: SMTP_PASSWORD
        sync: false
      - key: MAIL_FROM_ADDRESS
        value: noreply@your-domain.com
      - key: SENTRY_DSN
        sync: false
      - key: RAILS_LOG_TO_STDOUT
        value: "true"
      - key: RAILS_SERVE_STATIC_FILES
        value: "true"

  - type: psql
    name: rails-elearning-db
    plan: free
    region: singapore

  - type: redis
    name: rails-elearning-redis
    plan: free
    region: singapore
```

---

## Bước 8: Cấu hình Sentry

### Gemfile

```ruby
gem "sentry-ruby"
gem "sentry-rails"
```

### `config/initializers/sentry.rb`

```ruby
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1
end
```

---

## Bước 9: Cập nhật GitHub Actions

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2.2
          bundler-cache: true
      - name: Install dependencies
        run: bundle install --jobs 4 --retry 3
      - name: Run RuboCop
        run: bundle exec rubocop --parallel

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: rails_e_learning_test
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd="pg_isready"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:
      - uses: actions/checkout@v4
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2.2
          bundler-cache: true
      - name: Install dependencies
        run: bundle install --jobs 4 --retry 3
      - name: Setup test database
        run: bin/rails db:create db:schema:load RAILS_ENV=test
        env:
          DATABASE_URL: postgres://postgres:postgres@127.0.0.1:5432/rails_e_learning_test
      - name: Run tests
        run: bundle exec rspec
        env:
          DATABASE_URL: postgres://postgres:postgres@127.0.0.1:5432/rails_e_learning_test
          RAILS_ENV: test

  deploy:
    needs: [lint, test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Render
        uses: render-docs/action@v1
        with:
          apiKey: ${{ secrets.RENDER_API_KEY }}
          deployPreview: false
```

---

## Tổng kết

### Checklist hoàn thành Bước 1

- Render.com account + API Key (đã thêm vào GitHub Secrets)
- Render PostgreSQL Database + Connection String
- Render Redis + Connection String
- SendGrid API Key + Verified Sender Email
- Sentry DSN

### Checklist Agent sẽ làm (Bước 2-9)

- Migrate MySQL -> PostgreSQL
- Làm sạch Security
- Tạo .env.example
- Cập nhật production.rb
- Tạo puma.rb
- Tạo Procfile + render.yaml
- Cấu hình Sentry
- Cập nhật GitHub Actions
