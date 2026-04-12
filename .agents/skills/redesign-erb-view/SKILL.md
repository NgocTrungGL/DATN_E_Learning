---
name: Redesign ERB View
description: Step-by-step workflow for redesigning an existing Rails ERB view in this E-learning app. Covers codebase research, preserving backend logic (CanCan, Devise, Turbo), applying SOLID principles, and verifying against the platform design system.
---

# Instructions

Use this skill whenever tasked with redesigning or overhauling the UI of an existing ERB view.

## Step 1 — Research & SOLID Audit

Read these files **before coding**:
1. **Target View**: Identify Ruby variables and helpers.
2. **Controller**: Check auth (`authenticate_user!`), authorization (`authorize!`), and layout.
3. **SOLID Check**: Is there complex business logic in the view?
   - **S (Single Responsibility)**: If the view calculates values, move that logic to a **Decorator** or **Helper**.
   - **I (Interface Segregation)**: Ensure the view only receives the data it needs.

## Step 2 — Plan the New Structure

1. **Columns**: 1 (mobile), 2 (main + sidebar), or 3?
2. **Layout**: CSS Grid (preferred) or Flexbox.
3. **Outer Block**: e.g., `.lesson-page`, `.course-grid`.

## Step 3 — Rewrite the ERB (Logic Preservation)

- **Remove** Bootstrap layout classes (`row`, `col-*`).
- **Keep** all Ruby logic (`link_to`, `can?`, `user_signed_in?`).
- **Guard** all `current_user` calls:
  ```erb
  <% if user_signed_in? && current_user.enrolled?(@course) %>
    ...
  <% end %>
  ```

## Step 4 — SCSS Implementation

- Follow the **7-1 pattern**.
- Use shared components from `components/` (e.g., `.course-card`).
- Use shared mixins from `abstracts/` (e.g., `@include card-hover-lift`).

## Step 5 — Verify Layout & Performance

1. **Auth**: Test as Admin, Instructor, Student, and Guest.
2. **Devices**: 375px, 768px, 1440px.
3. **Logic**: Ensure form submissions (AJAX/Turbo) still work perfectly.
4. **Cleanliness**: Verify no business logic was added to the template.
