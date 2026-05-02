---
# Rule: Rails Architecture, SOLID & Design Patterns
# Enforces strict object-oriented design and clean Rails 7 patterns
---

# Rails Architecture & SOLID Principles

## 🔹 CODE LANGUAGE REQUIREMENT

**ALL Ruby, JavaScript, and ERB code must be written in ENGLISH ONLY:**
- ❌ **Forbidden**: Vietnamese variable names, method names, class names, file names, and code comments
- ✅ **Required**:
	- Method names: `def fetch_user_courses` (not `def lay_khoa_hoc_nguoi_dung`)
	- Variable names: `@enrolled_courses` (not `@khoaHocDangKy`)
	- Class names: `StudentEnrollmentService` (not `DichVuDangKyHocVien`)
	- File names: `student_enrollment_service.rb` (not `dich_vu_dang_ky_hoc_vien.rb`)
	- Comments: `# Handle course enrollment` (not `# Xử lý đăng ký khóa học`)

**EXCEPTION**: UI text labels (link text, button labels, error messages) should use Vietnamese via `i18n` locales (`config/locales/vi.yml`), but all code structure, identifiers, and comments must be English.

## 1. SOLID Principles (MANDATORY)

All system modifications must adhere to SOLID principles to avoid "fat models" and "callback hell".

| Principle | Enforcement in Rails |
|---|---|
| **Single Responsibility (S)** | Extract complex logic to **Service Objects** (`app/services`). Models should handle data/scopes only. |
| **Open/Closed (O)** | Use Strategy or Factory patterns for features requiring extension (e.g., payment gateways, report types). |
| **Liskov Substitution (L)** | Subclasses (e.g., STI models) must remain compatible with parent model expectations. |
| **Interface Segregation (I)** | Keep Controllers thin. Use **View Components** or **Helpers** to avoid broad data leakage to views. |
| **Dependency Inversion (D)** | Use Dependency Injection for external services (e.g., emailers, scrapers) to facilitate testing. |

## 2. Recommended Design Patterns

| Pattern | Use Case |
|---|---|
| **Service Objects** | Core business logic (e.g., `EnrollStudentService`, `ProcessOrderService`). |
| **Form Objects** | Validating and processing data that spans multiple models. |
| **Presenters / View Objects** | Complex UI logic (e.g., `CourseDecorator`) to clean up ERB templates. |
| **Strategy Pattern** | Handling different behaviors dynamically (e.g., `DiscountStrategy`). |
| **Command Pattern** | Encapsulating database transactions into manageable units. |

## 3. Controller & Model Separation

- **Models**: Responsible for Persistence, Validations, Scopes, and Relationships. **NO** business logic that spans multiple models.
- **Controllers**: Responsible for Orchestration. Thin actions calling Service Objects. No complex conditional logic.

## 4. Rails 7 Stack & Performance

- **Auth**: `devise` + `cancancan`. Use `authorize!` at the controller level.
- **Pagination**: `pagy` for high performance.
- **Frontend**: `turbo-rails` + `stimulus-rails` for SPA-like experience without heavy JS frameworks.
- **Safe Rendering**: Always guard `current_user` calls with `user_signed_in?`.

## 5. ERB & View Integrity

- Use **Strict BEM** for all custom CSS classes.
- Follow English i18n for all interface strings.
- Prefer **Partials** for repeated UI logic.

- Use **English i18n** for all user-facing interface labels (buttons, links, error messages) in `config/locales/en.yml`, and keep all i18n keys and code comments in English.
