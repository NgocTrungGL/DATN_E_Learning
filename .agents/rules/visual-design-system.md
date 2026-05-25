---
# Rule: Visual Design System — Premium E-Learning Platform
# Codifies the established design language from landing, course detail, and courses pages
# All new UI work must follow this rule
---

# Visual Design System — Premium E-Learning Platform

## 1. Design Philosophy

The platform's visual language is **professional education SaaS** — inspired by Udemy, Coursera, and Linear. Every page feels premium, structured, and trustworthy. The design uses a **dark hero sections + light content sections** contrast to create visual depth.

---

## 2. Color System

All colors reference SCSS variables from `abstracts/_variables.scss`. No arbitrary hex values.

### Primary Palette

| Token | Hex | Usage |
|---|---|---|
| `$primary` | `#2563eb` | CTAs, active states, links, badges |
| `$primary-dark` | `#1d4ed8` | Hover state of primary |
| `$primary-light` | `#eff6ff` | Light blue backgrounds, badges |
| `$accent` | `#0d9488` | Teal — secondary CTAs, accent highlights |
| `$accent-dark` | `#0a7a6f` | Teal hover state |

### Semantic Colors

| Token | Hex | Usage |
|---|---|---|
| `$success` | `#10b981` | Completion, badges, positive states |
| `$success-light` | `rgba(16, 185, 129, 0.12)` | Green backgrounds |
| `$warning` | `#f59e0b` | Gold/amber — quiz accents, alerts |
| `$warning-light` | `rgba(245, 158, 11, 0.12)` | Warning backgrounds |
| `$danger` | `#ef4444` | Errors, delete actions |
| `$danger-light` | `rgba(239, 68, 68, 0.12)` | Danger backgrounds |

### Surface Colors

| Token | Hex | Usage |
|---|---|---|
| `$bg` / `$bg-body` | `#f8fafc` | Page background |
| `$bg-dark` | `#0f172a` | Dark sections (hero, topbars) |
| `$bg-panel` | `#1e293b` | Dark panel — sidebars |
| `$surface` / `$white` | `#ffffff` | Card surfaces, modals |
| `$text-dark` | `#0f172a` | Primary text |
| `$text-mid` | `#475569` | Body text, descriptions |
| `$text-muted` | `#94a3b8` | Timestamps, hints, muted labels |
| `$border` | `#e2e8f0` | Light borders, dividers |
| `$border-dark` | `#334155` | Dark mode borders |

---

## 3. Typography

Defined in `abstracts/_typography.scss`. Uses Inter font (Google Fonts) loaded in layout.

### Scale

```scss
h1: clamp(1.8rem, 4vw, 2.5rem)  // 29px–40px, weight 800
h2: clamp(1.5rem, 3vw, 2.2rem)  // 24px–35px, weight 800
h3: 1.1rem–1.25rem, weight 700–800
h4: 1rem, weight 700
h5: 0.95rem, weight 600
h6: 0.9rem, weight 600
body: 0.95rem–1rem, line-height 1.6–1.7
label: 0.9rem, weight 600
small: 0.85rem
micro: 0.7rem–0.75rem, weight 700, letter-spacing 0.05em
```

### Usage Rules

- **Headings**: `font-weight: 800`, `letter-spacing: -0.02em` (h1/h2), dark color
- **Section titles**: `font-weight: 800`, `clamp()` responsive sizing
- **Labels**: `font-weight: 700`, `$text-mid` color
- **Micro text**: ALL CAPS with `letter-spacing: 0.08em` for badges, category labels, timestamps

---

## 4. Dark Hero Sections (Page Headers)

Every page with a dark hero follows this pattern:

```scss
.hero-section {
  background: linear-gradient(135deg, #0f172a 0%, #1e3a8a 55%, #0f172a 100%);
  position: relative;
  overflow: hidden;

  // Dot-grid overlay
  &::before {
    content: '';
    position: absolute;
    inset: 0;
    background-image: radial-gradient(circle, rgba(37, 99, 235, 0.12) 1px, transparent 1px);
    background-size: 26px 26px; // 28px on courses page
  }

  // Glowing orb
  &::after {
    content: '';
    position: absolute;
    top: -80px; right: -80px;
    width: 400px; height: 400px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(37, 99, 235, .22) 0%, transparent 65%);
  }
}
```

### Dark Hero Text

- **Titles**: white (`#ffffff`), `font-weight: 900`, `letter-spacing: -0.02em`
- **Subtitles**: `#93c5fd` (light blue) or `#cbd5e1`
- **Badges**: small pill with `rgba(37, 99, 235, .2)` background, `border: 1px solid rgba(37, 99, 235, .4)`, uppercase `letter-spacing: 0.09em`
- **Meta text**: `#94a3b8` or `#cbd5e1`

---

## 5. Card Component (Primary Surface)

Cards are the primary content container on light-background pages.

### Base Card

```scss
.card {
  background: $white;
  border-radius: $radius-lg;  // 16px
  padding: 1.25rem;           // generous internal spacing
  box-shadow: 0 4px 24px rgba(37, 99, 235, 0.08);
  border: 1px solid $border;
  transition: $transition;    // all 0.3s cubic-bezier(0.4, 0, 0.2, 1)
}
```

### Hover State

```scss
&:hover {
  box-shadow: 0 16px 40px rgba(37, 99, 235, 0.15);
  transform: translateY(-4px);
  border-color: rgba(37, 99, 235, 0.2);
}
```

### Card Anatomy

| Part | Token/Style |
|---|---|
| Thumbnail wrapper | `aspect-ratio: 16 / 9`, `border-radius: 12px` top |
| Body padding | `1.25rem` all sides |
| Title | `font-weight: 700`, `color: $text-dark`, truncate 2 lines |
| Description | `color: $text-mid`, `line-height: 1.6` |
| Footer divider | `border-top: 1px solid $border`, padding-top `0.85rem` |

---

## 6. Buttons

### Primary Button (Main CTA)

```scss
.btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  background: linear-gradient(135deg, $primary 0%, darken($primary, 8%) 100%);
  color: #ffffff;
  font-weight: 700;
  font-size: 0.9rem;
  min-height: 44px;
  padding: 0.75rem 1.5rem;
  border-radius: 12px;         // $radius-md or $radius-sm
  border: none;
  cursor: pointer;
  transition: $transition;

  &:hover {
    filter: brightness(1.05);
    transform: translateY(-1px);
    box-shadow: 0 6px 18px rgba($primary, 0.35);
  }
}
```

### Outline / Ghost Button

```scss
.btn-outline {
  background: transparent;
  color: $text-mid;
  border: 1.5px solid $border;
  border-radius: 12px;

  &:hover {
    background: $bg;
    color: $primary;
    border-color: $primary;
  }
}
```

### Icon Button

```scss
.btn-icon {
  width: 38px; height: 38px;
  border-radius: 50%;
  border: 1.5px solid $border;
  background: transparent;
  color: $text-mid;
  @include flex-center;

  &:hover {
    border-color: $primary;
    color: $primary;
    background: rgba($primary, 0.05);
  }
}
```

### Button Size Modifiers

| Size | Min Height | Padding | Font | Use Case |
|---|---|---|---|---|
| Default | 44px | 0.75rem 1.5rem | 0.9rem | Main CTAs |
| Small | 36px | 0.5rem 1rem | 0.82rem | Card actions, inline |
| Large | 52px | 1rem 2rem | 1.05rem | Hero CTAs, landing pages |

---

## 7. Form Elements

### Text Input / Textarea

```scss
.input {
  width: 100%;
  min-height: 44px;              // Same touch target as buttons
  border: 1.5px solid $border;
  border-radius: 12px;            // $radius-sm
  padding: 0.75rem 1rem;
  font-family: inherit;
  font-size: 0.95rem;
  color: $text-dark;
  background: $white;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;

  &::placeholder {
    color: $text-muted;
  }

  &:focus {
    outline: none;
    border-color: $primary;
    box-shadow: 0 0 0 3px rgba($primary, 0.12);
  }
}

.textarea {
  @extend .input;
  min-height: 140px;          // Multi-line form fields
  line-height: 1.75;
  resize: vertical;
}
```

### Label

```scss
.label {
  display: block;
  font-size: 0.9rem;
  font-weight: 700;
  color: $text-mid;
  margin-bottom: 0.5rem;
}
```

---

## 8. Modal / Dialog

Modals overlay dark content. They use a white card on a blurred backdrop.

```scss
.modal {
  position: fixed;
  inset: 0;
  z-index: 9500;
  display: flex;
  align-items: center;
  justify-content: center;
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.25s ease, visibility 0.25s ease;

  &.is-open {
    visibility: visible;
    opacity: 1;
  }

  &__backdrop {
    position: absolute;
    inset: 0;
    background: rgba(15, 23, 42, 0.6);
    backdrop-filter: blur(6px);
    -webkit-backdrop-filter: blur(6px);
  }

  &__dialog {
    position: relative;
    z-index: 1;
    width: 94%;
    max-width: 620px;         // 720px for large modals
    background: $white;
    border-radius: 16px;      // $radius-lg
    box-shadow: $shadow-lg, 0 0 0 1px rgba(0, 0, 0, 0.04);
    overflow: hidden;
    animation: modalSlideUp 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  }

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.5rem 2rem;    // Generous padding
    background: linear-gradient(135deg, $primary 0%, darken($primary, 8%) 100%);
    color: #ffffff;
  }

  &__body {
    padding: 2rem;            // Body breathing room
    background: $bg;
  }

  &__close {
    width: 40px; height: 40px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.15);
    border: 1px solid rgba(255, 255, 255, 0.25);
    color: #ffffff;
    @include flex-center;
    font-size: 0.95rem;
    cursor: pointer;
    transition: background 0.2s ease, transform 0.2s ease;

    &:hover {
      background: rgba(255, 255, 255, 0.25);
      transform: rotate(90deg);
    }
  }
}
```

---

## 9. Spacing System

All spacing is in multiples of 4px. Use these tokens consistently:

| Token | Value | Use |
|---|---|---|
| Tight | 0.25rem (4px) | Icon-to-text gap |
| Small | 0.5rem (8px) | Inline gaps, compact spacing |
| Default | 0.75rem (12px) | Compact padding |
| Standard | 1rem (16px) | Standard padding unit |
| Card Padding | 1.25rem (20px) | Card inner padding |
| Section Internal | 1.5rem (24px) | Section internal padding |
| Section Gap | 2rem (32px) | Section separation |
| Major Section | 3rem–5rem | Major vertical padding |

---

## 10. Border Radius Scale

| Token | Value | Use |
|---|---|---|
| `$radius-sm` | 8px | Buttons, inputs, small pills |
| `$radius-md` | 12px | Cards, panels |
| `$radius-lg` | 16px | Large containers, modals |
| `$radius-xl` | 20px | Extra large containers |
| 999px | Full pill | Badges, tags, full-circle |

---

## 11. Shadow System

```scss
$shadow-sm:   0 1px 4px rgba(0, 0, 0, 0.07);      // Subtle resting card
$shadow-md:   0 4px 16px rgba(0, 0, 0, 0.08);     // Standard card
$shadow-lg:   0 12px 40px rgba(0, 0, 0, 0.1);     // Strong card/modal
$shadow-blue: 0 8px 28px rgba(37, 99, 235, 0.22); // Blue-tinted hover/active
```

**Card hover shadow** (light pages): `0 16px 40px rgba(37, 99, 235, 0.15)`

---

## 12. Animations & Transitions

### Standard Transition

```scss
$transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
transition: $transition;
```

### Card Hover Lift

```scss
&:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 40px rgba(37, 99, 235, 0.15);
  border-color: rgba(37, 99, 235, 0.2);
}
```

### Modal Slide Up

```scss
@keyframes modalSlideUp {
  from { opacity: 0; transform: translateY(20px) scale(0.97); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
```

### Button Hover Lift

```scss
&:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba($primary, 0.35);
}
```

---

## 13. Section Header Pattern

Use this pattern for all page section headers:

```scss
.section-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  margin-bottom: 3rem;
}

.section-badge {
  display: inline-block;
  background: $primary-light;
  color: $primary;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 0.3rem 1rem;
  border-radius: 999px;
  margin-bottom: 1rem;
}

.section-title {
  font-size: clamp(1.8rem, 4vw, 2.5rem);
  font-weight: 800;
  color: $text-dark;
  line-height: 1.2;
  margin-bottom: 1rem;
}

.section-subtitle {
  font-size: 1.05rem;
  color: $text-muted;
  max-width: 580px;
  margin: 0 auto;
  line-height: 1.7;
}
```

---

## 14. Empty State Pattern

```scss
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 3rem 2rem;
  background: $white;
  border: 1px dashed $border;
  border-radius: $radius-lg;

  &__icon {
    font-size: 2.5rem;
    margin-bottom: 1rem;
    opacity: 0.4;
  }

  &__title {
    font-size: 1.1rem;
    font-weight: 700;
    color: $text-dark;
    margin-bottom: 0.5rem;
  }

  &__subtitle {
    font-size: 0.875rem;
    color: $text-muted;
    max-width: 300px;
    line-height: 1.6;
  }
}
```

---

## 15. Responsive Breakpoints

| Breakpoint | Width | Use |
|---|---|---|
| Mobile | Default (375px+) | Base styles |
| Tablet | `@media (min-width: 768px)` | Grid columns, side-by-side layouts |
| Desktop | `@media (min-width: 1024px)` | Sticky sidebars, 2-column layouts |
| Wide | `@media (min-width: 1440px)` | Max-width containers, full-width grids |

---

## 16. Iconography

Exclusively **Bootstrap Icons 1.11.0** (loaded via CDN). Usage: `<i class="bi bi-<icon-name>"></i>`.

**Rule**: Bootstrap Icons is an icon library only — NOT the Bootstrap CSS framework. Never use Bootstrap CSS classes.

---

## 17. Consistency Checklist

Before shipping any UI component, verify:

- [ ] All colors come from SCSS tokens (no arbitrary hex in component files)
- [ ] `font-weight: 800` for headings, `700` for labels, `600` for body emphasis
- [ ] Cards use `$shadow-md` resting, `$shadow-blue` or `0 16px 40px rgba(37, 99, 235, 0.15)` on hover
- [ ] Border radius: `$radius-sm` for buttons/inputs, `$radius-lg` for cards/modals
- [ ] Hover states include: color change + `translateY(-1px)` or `translateY(-4px)` + shadow increase
- [ ] All interactive elements have `cursor: pointer`
- [ ] Touch targets minimum 44px
- [ ] `transition: $transition` on all interactive elements
- [ ] Responsive at 375px, 768px, 1024px, 1440px
- [ ] Bootstrap Icons used for icons only (no Bootstrap CSS classes)
