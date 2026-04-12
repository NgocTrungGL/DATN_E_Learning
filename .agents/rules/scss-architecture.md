---
# Rule: SCSS Architecture & Styling Conventions (7-1 Pattern)
# Enforces strict modular SCSS, BEM, and centralized design tokens
---

# SCSS Architecture & Styling Conventions

## 1. 7-1 Architectural Pattern (MANDATORY)

The platform follows a strict 7-1 architecture to ensure scalability and maintainability.

| Layer | Directory | Purpose |
|---|---|---|
| **Abstracts** | `app/assets/stylesheets/abstracts/` | Logic & config: `_variables.scss`, `_mixins.scss`, `_typography.scss` |
| **Base** | `app/assets/stylesheets/base/` | Boilerplate & resets: `_base.scss`, `_reset.scss` |
| **Components** | `app/assets/stylesheets/components/` | Reusable UI widgets: `_course_card.scss`, `_buttons.scss` |
| **Pages** | `app/assets/stylesheets/pages/` | Page-specific layout & overrides: `_lesson.scss`, `_courses.scss` |

- **HARD RULE**: No local variable or mixin definitions allowed in **Pages**.
- **HARD RULE**: All page files MUST use tokens from **Abstracts**.

## 2. Centralized Design Tokens

### Abstracts Layer
- **`abstracts/_variables.scss`**: The single source of truth for colors, radii, shadows, and timings.
- **`abstracts/_mixins.scss`**: Shared utilities like `flex-center`, `flex-between`, and `line-clamp`.
- **`abstracts/_typography.scss`**: Centralized font management and heading styles.

### Component Layer
- Reusable UI elements (cards, buttons, icons) must live in `components/`.
- Use `@extend` or `@include` shared mixins to build components.

## 3. BEM Naming Convention (STRICT)

Use **strict 3-level BEM**: `.block__element--modifier`.
- Maximum SCSS nesting depth: **3 levels**.
- Never use generic names like `.title`. Always prefix with the block name.

## 4. Responsive Breakpoints

Always use these **three breakpoints** with a **mobile-first** approach:
- **Mobile**: Default styles (base 375px)
- **Tablet**: `@media (min-width: 768px)`
- **Desktop**: `@media (min-width: 1440px)`

## 5. Implementation Workflow

1. Create/Use variables in `abstracts/_variables.scss`.
2. Extract shared logic to `abstracts/_mixins.scss`.
3. Build reusable UI in `components/`.
4. Page-specific files in `pages/` should ONLY contain layout-level styling.
5. Import all files in `app/assets/stylesheets/application.scss` in correct layer order.
