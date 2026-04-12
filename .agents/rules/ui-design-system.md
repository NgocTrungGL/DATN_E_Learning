---
# Rule: UI Design System & Component Consistency
# Ensures new UI work matches the platform's established visual language
---

# UI Design System & Component Consistency

## Brand Identity

This is a **Vietnamese E-learning SaaS platform** (Udemy/Coursera-style). All UI must feel premium, polished, and consistent. The visual language is:

- **Professional Blue & Teal** — education-grade, trustworthy, clean
- **Inter font** (Google Fonts) — primary typeface across all modernized pages
- **Dark top bars** — lesson player, course detail sticky header
- **Light backgrounds** — public pages use `#f8fafc` or `#ffffff`
- **Dark sections** — marketing sections (flash sales, learning paths) use `#0f172a` / `#1e293b`

## Color Palette (ALWAYS use these — never arbitrary hex values)

| Token | Value | Usage |
|---|---|---|
| `$primary` / `#2563eb` | Platform blue | CTAs, active states, links |
| `$primary-dark` / `#1d4ed8` | Hover state of primary | Button hover |
| `$accent` / `#0d9488` | Teal | Secondary CTAs, accent pills, gradients |
| `$accent-dark` / `#0a7a6f` | Teal hover | |
| `#f8fafc` | Off-white | Page backgrounds |
| `#0f172a` | Deep navy | Dark sections, topbars |
| `#1e293b` | Dark panel | Sidebar, card backgrounds in dark sections |
| `#475569` | Mid text | Body text, descriptions |
| `#94a3b8` | Muted text | Timestamps, hints, labels |
| `#e2e8f0` | Border | Cards, dividers |
| `#16a34a` / `#dcfce7` | Green / green BG | Success, completion, badges |
| `#f59e0b` | Gold/amber | Quiz/trophy accent |

## Typography Scale

```scss
// Headings — fluid with clamp()
h1: clamp(1.5rem, 3vw, 2.25rem)
h2: clamp(1.25rem, 2.5vw, 1.75rem)
h3: 1.1rem - 1.25rem, font-weight: 700-800
// Body
body: 0.95rem - 1rem, line-height: 1.7
// Small / meta
small: 0.78rem - 0.85rem
// UI labels / badges
micro: 0.7rem - 0.75rem, font-weight: 700, letter-spacing: 0.05em
```

## Spacing System

Use multiples of **0.25rem** (4px). Common values:
- `0.25rem` (4px) — tight inline gaps
- `0.5rem` (8px) — icon-to-text gap
- `0.75rem` (12px) — compact padding
- `1rem` (16px) — standard padding unit
- `1.25rem` (20px) — card inner padding
- `1.5rem` (24px) — section internal padding
- `2rem` (32px) — section separation
- `3rem–5rem` — major section vertical padding

## Border Radius

| Usage | Value |
|---|---|
| Buttons, inputs, small pills | `8px` |
| Cards, panels, modals | `12px` |
| Full pills (badges, tags) | `999px` |
| Large containers | `16px` |

## Shadow System

```scss
$shadow-card:  0 1px 4px rgba(0,0,0,0.07);      // resting card
$shadow-hover: 0 6px 24px rgba(37,99,235,0.12);  // card hover (blue tint)
$shadow-cta:   0 4px 12px rgba(37,99,235,0.25);  // primary CTA button
```

## Button Patterns

**Primary CTA** — gradient from `$primary` to `$accent`:
```scss
background: linear-gradient(135deg, #2563eb, #0d9488);
color: #fff;
border: none;
border-radius: 8px;
box-shadow: 0 4px 12px rgba(37,99,235,0.25);
// Hover: deepen gradient + increase shadow
```

**Secondary / outline** — border `$border`, bg white:
```scss
border: 1.5px solid #e2e8f0;
color: #475569;
background: #fff;
border-radius: 8px;
// Hover: blue border + blue text
```

**Ghost / text** — transparent bg, colored text only.

## Icon Library

Exclusively **Bootstrap Icons 1.11.0** (loaded via CDN in all layouts):
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
```
Use `<i class="bi bi-<name>"></i>` syntax. Never use other icon libraries unless adding a new CDN link.

## Interaction Patterns

- **Hover transitions**: `all 0.2s cubic-bezier(0.4, 0, 0.2, 1)` (or the `$transition: all 0.3s ease` token)
- **Card hover**: `translateY(-2px)` lift + increased box-shadow
- **Button hover**: `translateY(-1px)` + deeper gradient/shadow
- **Active sidebar item**: `border-left: 3px solid $primary` + light blue background `#eff6ff`

## Layout Patterns

| Context | Layout approach |
|---|---|
| Public pages (courses list, landing) | CSS Grid or Flexbox, max-width ~1280px centered |
| Course detail | Sticky sidebar: `position: sticky; top: 80px` |
| Lesson player | Full-viewport CSS Grid `1fr 340px`, `height: 100vh; overflow: hidden` |
| Marketing sections | Full-bleed (no max-width on outer), inner content max-width 1280px |
| Video embeds | Always `aspect-ratio: 16 / 9;` with iframe `position: absolute; inset: 0` |

## Consistency Checklist for New UI Components

Before marking a component done, verify:
- [ ] Uses Inter font (loaded in layout `<head>`)
- [ ] Colors are from the palette above (no arbitrary hex)
- [ ] Border radius matches the scale
- [ ] Hover state defined
- [ ] Mobile-first responsive with 375px/768px/1440px breakpoints
- [ ] Vietnamese text labels match existing terminology
- [ ] No Bootstrap utility layout classes used in the new SCSS
