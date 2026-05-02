---
name: Add New Page SCSS
description: Step-by-step workflow for creating a properly structured BEM SCSS file for a new page or section in this E-learning Rails app. Covers token setup, BEM naming, breakpoints, and integration into the asset pipeline.
---

# Instructions

Use this skill whenever implementing CSS/SCSS for a new page view, a new landing section, or a significant new UI component that doesn't already have a stylesheet.

## ⚠️ CODE LANGUAGE REQUIREMENT: ENGLISH ONLY

**All SCSS code must use English:**
- ❌ **Forbidden**: Vietnamese class names (`.nut-chinh`), variable names (`$chieuDai`), comments (`// Thành phần thẻ`)
- ✅ **Required**:
  - File names: `_course-detail.scss` (not `_chi-tiet-khoa-hoc.scss`)
  - Class names: `.course-detail__header` (not `.chi-tiet-khoa__phan-dau`)
  - Comments: `// Course detail section` (not `// Phần chi tiết khóa học`)
  - Variable references: Use `$primary`, `$accent`, `$bg` (already defined in abstracts/)

## Step 1 — Identify the Scope

Before writing any SCSS, determine:
- **Is this page-level** (only used by one controller action)? → File goes in `app/assets/stylesheets/pages/_<page-name>.scss`.
- **Is this a shared component** (used across multiple pages)? → File goes in `app/assets/stylesheets/components/_<component-name>.scss`.

## Step 2 — Create the SCSS File (7-1 Pattern)

Create the file at the appropriate path. **NEVER** define local variables or mixins. Instead, import from `abstracts/`:

```scss
// ============================================================
// [PAGE NAME] — Pure SCSS, Strict BEM
// Part of the 7-1 Architectural Pattern
// ============================================================

// ── Shared Tokens (Already available globally via application.scss) ──
// Use variables like $primary, $accent, $bg, $surface, $text-dark, $text-muted
// Use mixins like @include flex-center, @include flex-between, @include line-clamp(2)

// ── Page-Level Styles ─────────────────────────────────────────

.my-page-block {
  background: $bg;
  @include section-padding;

  &__inner {
    @include inner-container;
  }
  ## ⚠️ CODE LANGUAGE REQUIREMENT: ENGLISH ONLY
}
  **All SCSS code must use English:**
  - ❌ **Forbidden**: Vietnamese class names (`.nut-chinh`), variable names (`$chieuDai`), comments (`// Thành phần thẻ`)
  - ✅ **Required**:
    - File names: `_course-detail.scss` (not `_chi-tiet-khoa-hoc.scss`)
    - Class names: `.course-detail__header` (not `.chi-tiet-khoa__phan-dau`)
    - Comments: `// Course detail section` (not `// Phần chi tiết khóa học`)
    - Variable references: Use `$primary`, `$accent`, `$bg` (already defined in abstracts/)

```

## Step 3 — Write BEM Blocks

Define one BEM block per logical UI area. Rules:
- Block: `.page-name` or `.component-name` (kebab-case)
- Element: `.block__element`
- Modifier: `.block--modifier`
- **Max nesting: 3 levels**.

## Step 4 — Add Responsive Breakpoints

Use **mobile-first**: styles target 375px base, then add queries:

```scss
.my-section {
  display: grid;
  grid-template-columns: 1fr;

  @media (min-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }

  @media (min-width: 1440px) {
    grid-template-columns: repeat(3, 1fr);
    @include inner-container;
  }
}
```

## Step 5 — Register the File in application.scss

Add the import in the correct layer section:

```scss
// 4. Components
@import "components/my-component";

// 5. Pages
@import "pages/my-new-page";
```

## Step 6 — Verify

1. Start server: `bin/rails server`.
2. check layout at 375px, 768px, and 1440px.
3. Ensure no hardcoded hex values were used (use `grep` to check).
