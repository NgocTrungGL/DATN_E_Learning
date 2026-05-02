---
# Rule: Button System Standardization
# Enforces strict button sizing, variants, and context-based usage
---

# Button System Standardization

## Purpose

This rule defines a single, consistent button system for the platform. The goal is to prevent oversized buttons from breaking UI rhythm and to keep all interactive controls visually balanced.

## 1. Core Button Structure

Every button element (`<a>` or `<button>`) must use the platform's core `.btn` component together with the approved modifiers.

The `.btn` base class must only contain structural styles and shared interaction behavior. It must not hard-code arbitrary padding, width, height, or font size per instance.

```scss
// components/_buttons.scss
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  border-radius: 8px;
  font-family: 'Inter', sans-serif;
  font-weight: 500;
  text-decoration: none;
  border: transparent 1.5px solid;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
  white-space: nowrap;

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
}
```

## 2. Size Modifiers

Choose button size based on the available container space and the visual importance of the action.

| Modifier | Size | Padding | Font Size | Required Context |
|---|---|---|---|---|
| `.btn--sm` | Small | `6px 12px` | `0.85rem` | Lists, tables, card actions, narrow spaces |
| None | Medium | `8px 16px` | `0.95rem` | Default size for form submits and main navigation actions |
| `.btn--lg` | Large | `12px 24px` | `1.1rem` | Hero sections, landing pages, highly important CTA actions |

## 3. Variant Modifiers

Button variants define action priority and visual emphasis.

- `.btn--primary`: Main accent color or gradient. Use for the most important action in a small UI group. Limit to one primary button per local action group.
- `.btn--secondary`: White background, light gray border `#e2e8f0`, dark text. Use for secondary actions such as cancel, view details, or supporting downloads.
- `.btn--ghost`: Transparent background with no border. Use for low-priority inline actions such as edit or delete links.

## 4. Usage Checklist for AI-Generated UI

Before generating HTML or ERB with buttons, verify:

- [ ] Is the button inside a list, table, or card with limited space? Use `.btn--sm`.
- [ ] Does the same container contain multiple buttons? Only one may use `.btn--primary`; the rest must use `.btn--secondary` or `.btn--ghost`.
- [ ] Does the button include an icon? Use Bootstrap Icons with proper spacing via `gap`.

## 5. Practical Examples

### Incorrect

```erb
<div class="resource-item">
  <span>PDF document</span>
  <a href="#" class="btn btn--primary">Download</a>
</div>
```

### Correct

```erb
<div class="resource-item">
  <span>PDF document</span>
  <a href="#" class="btn btn--secondary btn--sm">
    <i class="bi bi-download"></i> Download
  </a>
</div>
```

## 6. Design Principle

The button system must preserve visual hierarchy. If a button feels too large for its container, reduce the size modifier first before changing layout spacing.

## 7. Enforcement Notes

- Never hard-code ad hoc spacing on individual button instances.
- Never introduce a new button shape or typography rule outside the shared component.
- Keep the button component consistent across the platform so that layout density remains predictable.
