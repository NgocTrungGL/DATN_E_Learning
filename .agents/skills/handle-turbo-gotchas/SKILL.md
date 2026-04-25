---
name: Handle Turbo Gotchas
description: Best practices for handling Hotwire Turbo issues related to CSS leakage and JavaScript event listeners.
---

# Handle Turbo Gotchas

In modern Rails applications using Hotwire Turbo, you must be careful about how you write CSS and JavaScript. Because Turbo does not perform a full browser page reload on navigation, resources from previous pages can "leak" or fail to initialize.

Follow these strict guidelines when working on frontend features in a Turbo application.

## 1. Avoid Inline `<style>` Tags in `<head>`
**The Problem**: Turbo merges `<head>` tags across page navigations. If you have a specific layout with an inline `<style>` block (e.g., locking the scrollbar with `body { overflow: hidden; }`), Turbo will **retain** that style when you navigate to a different layout. This causes CSS to leak randomly, making the UI unstable (sometimes working on hard refresh, breaking on navigation).

**The Solution**:
1. Remove all inline `<style>` blocks from layout ERB files.
2. Put the CSS into scoped SCSS files (e.g., `_layout_learning.scss`).
3. Namespace the CSS using a class added to the `<body>` tag.
   ```html
   <!-- Bad: -->
   <head>
     <style>body { background: #000; }</style>
   </head>
   <body>...</body>

   <!-- Good: -->
   <body class="layout-learning">...</body>
   ```
   ```scss
   // SCSS
   body.layout-learning {
     background: #000;
   }
   ```

## 2. Use `turbo:load` Instead of `DOMContentLoaded`
**The Problem**: `DOMContentLoaded` is fired by the browser exactly **once** when the initial HTML document is completely loaded and parsed. When Turbo navigates to a new page, it intercepts the link and swaps the `<body>` and merges the `<head>`. Because the browser is not doing a full reload, **`DOMContentLoaded` is never fired again**. This causes JavaScript animations, libraries, and logic (like `[data-reveal]`) to break or disappear when navigating between pages.

**The Solution**:
Replace `DOMContentLoaded` with Turbo's equivalent event: `turbo:load`. This event fires on the initial page load *and* after every Turbo navigation.

```javascript
// ❌ Bad: Will only run once, breaks on Turbo navigation
document.addEventListener('DOMContentLoaded', function() {
  initAnimations();
});

// ✅ Good: Runs on initial load and every Turbo navigation
document.addEventListener('turbo:load', function() {
  initAnimations();
});
```

## 3. Verify CDN Links in All Layouts
**The Problem**: If `application.html.erb` loaded Google Fonts and Bootstrap Icons via CDN, but `admin.html.erb` did not, Turbo nav works because it retains the `<link>` from the previous page's `<head>`. However, a Hard Refresh (F5) on the Admin page will lose the CSS/Icons completely.

**The Solution**:
Ensure all layouts (`auth`, `admin`, `learning`, `business`, etc.) explicitly include the necessary remote CDNs (Fonts, Icons) in their `<head>` section before the main `application` stylesheet link.
