---
# Rule: UI Design System & Component Consistency
# Ensures new UI work matches the platform's established visual language
# CRITICAL: CSS/SCSS-only approach — NO Bootstrap CSS framework, only custom styling
---

# UI Design System & Component Consistency

## 🔹 CODE LANGUAGE REQUIREMENT

**ALL code written must use ENGLISH ONLY:**
- ❌ **Forbidden**: Vietnamese variable names, function names, class names, file names, comments
- ✅ **Required**:
  - Comments: `// Fetch user data` (not `// Lấy dữ liệu người dùng`)
  - Variables: `const userEmail = "...";` (not `const emailNguoiDung = "...";`)
  - Classes: `.btn-primary` (not `.nut-chinh`)
  - Function names: `fetchCourses()` (not `layKhoaHoc()`)

**EXCEPTION**: None. UI text labels, helper text, error messages, and other user-facing content must also be in English.

## Brand Identity

This is a **Vietnamese E-learning SaaS platform** (Udemy/Coursera-style). All UI must feel premium, polished, and consistent. The visual language is:

- **Professional Blue & Teal** — education-grade, trustworthy, clean
- **Inter font** (Google Fonts) — primary typeface across all modernized pages
- **Dark top bars** — lesson player, course detail sticky header
- **Light backgrounds** — public pages use `#f8fafc` or `#ffffff`
- **Dark sections** — marketing sections (flash sales, learning paths) use `#0f172a` / `#1e293b`

## ⚠️ CRITICAL STYLING REQUIREMENT

**All UI styling MUST be implemented using CSS/SCSS only.** NO Bootstrap CSS framework utilities are allowed in any new code:
- ❌ **Forbidden**: Bootstrap utility classes such as `.btn-outline-secondary`, `.btn-sm`, `.me-4`, `.btn-close`, `data-bs-*` attributes
- ✅ **Required**: Platform button component classes following BEM convention, centered on the core `.btn` base class (e.g., `.btn`, `.btn--primary`, `.btn--secondary`, `.btn--ghost`, `.btn--sm`, `.btn--lg`)
- ✅ **Allowed**: Bootstrap Icons CDN for icon-only usage (not the CSS framework)

All new components must be created in `app/assets/stylesheets/components/` using centralized design tokens from `abstracts/`.

## Color Palette (ALWAYS use SCSS variables — never arbitrary hex values)

### Core Colors (defined in `abstracts/_variables.scss`)

| SCSS Variable | Hex Value | Usage |
|---|---|---|
| `$primary` | `#2563eb` | Platform blue — CTAs, active states, links |
| `$primary-dark` | `#1d4ed8` | Hover state of primary button |
| `$primary-light` | `#eff6ff` | Light blue background, active sidebar items |
| `$accent` | `#0d9488` | Teal — Secondary CTAs, accent accents |
| `$accent-dark` | `#0a7a6f` | Teal hover/active state |
| `$accent-light` | `rgba(13, 148, 136, 0.1)` | Subtle teal background |
| `$success` | `#10b981` | Green — Completion, badges, positive states |
| `$success-light` | `rgba(16, 185, 129, 0.12)` | Green background |
| `$warning` | `#f59e0b` | Gold/amber — Quiz accents, alerts |
| `$warning-light` | `rgba(245, 158, 11, 0.12)` | Warning background |
| `$danger` | `#ef4444` | Red — Errors, delete actions |
| `$danger-light` | `rgba(239, 68, 68, 0.12)` | Danger background |
| `$bg` / `$bg-body` | `#f8fafc` | Off-white page backgrounds |
| `$bg-dark` | `#0f172a` | Deep navy — dark sections, topbars |
| `$bg-panel` | `#1e293b` | Dark panel — sidebars, card bg in dark sections |
| `$surface` / `$white` | `#ffffff` | Pure white surfaces |
| `$text-dark` | `#0f172a` | Primary text |
| `$text-mid` | `#475569` | Body text, descriptions |
| `$text-muted` | `#94a3b8` | Timestamps, hints, muted labels |
| `$border` | `#e2e8f0` | Light borders, dividers |
| `$border-dark` | `#334155` | Dark mode borders |

## Spacing System

Use SCSS tokens for consistency. All values are multiples of **0.25rem** (4px):
- `0.25rem` (4px) — tight inline gaps
- `0.5rem` (8px) — icon-to-text gap
- `0.75rem` (12px) — compact padding
- `1rem` (16px) — standard padding unit
- `1.25rem` (20px) — card inner padding
- `1.5rem` (24px) — section internal padding
- `2rem` (32px) — section separation
- `3rem–5rem` — major section vertical padding

## Border Radius System

Token-based (`abstracts/_variables.scss`):
| SCSS Variable | Value | Usage |
|---|---|---|
| `$radius-sm` | `8px` | Buttons, inputs, small pills |
| `$radius-md` | `12px` | Cards, panels, modals |
| `$radius-lg` | `16px` | Large containers |
| `$radius-xl` | `20px` | Extra large containers |
| `999px` | Full pills | Badges, tags, full-circle buttons |

## Shadow System

Token-based (`abstracts/_variables.scss`):
```scss
$shadow-sm:   0 1px 4px rgba(0, 0, 0, 0.07);     // Subtle resting card
$shadow-md:   0 4px 16px rgba(0, 0, 0, 0.08);    // Standard card shadow
$shadow-lg:   0 12px 40px rgba(0, 0, 0, 0.1);    // Strong card/modal shadow
$shadow-blue: 0 8px 28px rgba(37, 99, 235, 0.22);// Blue-tinted (hover/active)
```

## Typography Scale

Defined in `abstracts/_typography.scss`, uses fluid sizing with `clamp()`:

```scss
// Headings — responsive with clamp()
h1: clamp(1.5rem, 3vw, 2.25rem)        // 24px–36px
h2: clamp(1.25rem, 2.5vw, 1.75rem)     // 20px–28px
h3: 1.1rem–1.25rem, font-weight: 700–800
h4: 1rem, font-weight: 700
h5: 0.95rem, font-weight: 600
h6: 0.9rem, font-weight: 600

// Body text
body: 0.95rem–1rem, line-height: 1.6–1.7
label: 0.9rem, font-weight: 600
input: 0.95rem
small: 0.85rem–0.9rem
// UI micro labels
.micro: 0.7rem–0.75rem, font-weight: 700, letter-spacing: 0.05em
```

## Button Component Library

All buttons are defined in `components/_buttons.scss` using SCSS `@extend`. Use these classes exclusively:

### Primary Button (`.btn-primary`)
```scss
.btn-primary {
  background: $primary;
  color: #fff;
  border: none;
  border-radius: $radius-sm;
  padding: 0.75rem 1.5rem;
  transition: $t;

  &:hover {
    background: $primary-dark;
    box-shadow: 0 4px 12px rgba($primary, 0.3);
    transform: translateY(-1px);
  }
}
```

### Accent Button (`.btn-accent`)
Secondary CTA using teal accent color:
```scss
.btn-accent {
  background: $accent;

  &:hover {
    background: $accent-dark;
    box-shadow: 0 4px 12px rgba($accent, 0.2);
  }
}
```

### Outline Button (`.btn-outline`)
Secondary button with border:
```scss
.btn-outline {
  background: transparent;
  border: 1.5px solid $border;
  color: $text-mid;

  &:hover {
    background: $bg;
    color: $primary;
    border-color: $primary;
  }
}
```

### Icon Button (`.btn-icon`)
Circular button for icons (cart, favorite, etc.):
```scss
.btn-icon {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  @include flex-center;
  border: 1.5px solid $border;
  background: transparent;
  color: $text-mid;

  &:hover {
    border-color: $primary;
    color: $primary;
    background: rgba($primary, 0.05);
  }
}
```

## Icon Library

Exclusively **Bootstrap Icons 1.11.0** (loaded via CDN in layout files for icon-only purposes):
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
```
Usage: `<i class="bi bi-<icon-name>"></i>`

⚠️ Bootstrap Icons is **icon library only** — NOT the Bootstrap CSS framework.

## Global Mixins (from `abstracts/_mixins.scss`)

Reusable SCSS mixins for common patterns:

```scss
@mixin flex-center        // Flexbox center (align + justify)
@mixin flex-between       // Space-between flex layout
@mixin flex-column        // Flex column layout
@mixin line-clamp($lines) // Text truncation with ellipsis
@mixin section-padding    // Responsive section padding (5rem desktop, 3rem mobile)
@mixin inner-container    // Max-width 1280px centered with responsive padding
@mixin card-hover-lift    // Card hover animation (lift + shadow)
```

## Card Component (`.course-card`, `.my-course-card`)

Established in `components/_course_card.scss` and `components/_my_course_card.scss`:

- Base card styling with `$shadow-sm`
- Hover state with `@mixin card-hover-lift` (translateY-4px + blue shadow)
- Progress bar using `$success` color
- Responsive grid layout (1 col mobile, 2–3 cols tablet/desktop)
- Image aspect ratio: `aspect-ratio: 16 / 9`

## Tab Component (`.lesson-tabs`)

Established in `components/_lesson_tabs.scss`:

- BEM naming: `.lesson-tabs`, `.lesson-tabs__nav`, `.lesson-tabs__tab--active`
- Active indicator using `border-bottom: 3px solid $primary`
- Responsive: stacked on mobile, horizontal on tablet+
- Smooth transition between states

## Interaction Patterns

### Transitions
- Standard: `$t: all 0.22s ease` (used via `transition: $t`)
- Legacy support: `$transition: all 0.3s ease`
- Cubic-bezier: `$t-cubic: all 0.22s cubic-bezier(0.4, 0, 0.2, 1)`

### Hover Effects
- **Button hover**: `translateY(-1px)` + shadow increase + color/background change
- **Card hover**: `translateY(-4px)` + `$shadow-lg` (via `@mixin card-hover-lift`)
- **Link hover**: Underline appear or color change to `$primary`
- **Active sidebar**: `border-left: 3px solid $primary` + background `$primary-light`

### Focus States
- Use `outline: 2px solid $primary` for keyboard accessibility
- Offset outline by `-2px`

## Layout Patterns

| Context | Layout approach |
|---|---|
| Public pages (courses list, landing) | CSS Grid or Flexbox, `max-width: 1280px` centered with `@mixin inner-container` |
| Course detail page | Sticky sidebar using `position: sticky; top: 80px` |
| Lesson player | Full-viewport CSS Grid `1fr 340px`, `height: 100vh; overflow: hidden` |
| Marketing sections | Full-bleed outer container, inner content `max-width: 1280px` |
| Video embeds | Always `aspect-ratio: 16 / 9;` with iframe `position: absolute; inset: 0` |
| Admin panels | Flex column with header, sidebar, and main content area |

## Responsive Breakpoints (Mobile-First)

Defined as SCSS mixins or media queries:
- **Mobile (default)**: 375px+ — base styles
- **Tablet**: `@media (min-width: 768px)` — adjust layouts, grid columns
- **Desktop**: `@media (min-width: 1440px)` — full-width layouts, multi-column grids

## New Component Workflow

When creating a new component, follow this checklist:

1. **Define token usage**: All colors, shadows, radii must come from `abstracts/_variables.scss`
2. **Create in `components/` directory**: File naming: `_component-name.scss`
3. **Use BEM naming**: `.component__element--modifier` (max nesting depth: 3 levels)
4. **Import in `application.scss`**: Add `@import "components/component-name"`
5. **Use mixins**: Leverage `@mixin flex-center`, `@mixin card-hover-lift`, etc.
6. **Define hover/active states**: Every interactive element must have a transition and hover state
7. **Test responsiveness**: Verify at 375px, 768px, 1440px breakpoints
8. **No custom hex colors**: Use SCSS variables only
9. **No Bootstrap utilities**: All styling via custom SCSS classes

## Consistency Checklist for New UI Components

Before marking a component done, verify:
- [ ] **CSS/SCSS only**: No Bootstrap CSS framework classes (`.btn`, `.me-4`, `data-bs-*`)
- [ ] **Uses Inter font**: Loaded in layout `<head>`
- [ ] **All colors from tokens**: No arbitrary hex values in component files
- [ ] **Border radius matches scale**: Use `$radius-sm`, `$radius-md`, `$radius-lg`, `$radius-xl`
- [ ] **Hover/focus states defined**: Interactive elements have transitions and visual feedback
- [ ] **Mobile-first responsive**: Base styles work at 375px, enhanced at 768px+ and 1440px+
- [ ] **Vietnamese labels match terminology**: Consistent with existing UI text
- [ ] **BEM naming convention**: Proper structure, max 3 nesting levels
- [ ] **Uses centralized mixins**: `@mixin flex-center`, `@mixin line-clamp`, `@mixin card-hover-lift`, etc.
- [ ] **Imported in `application.scss`**: Component file is part of the build
- [ ] **No local variables in page files**: Page SCSS only uses tokens from abstracts
