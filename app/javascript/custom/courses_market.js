/**
 * courses_market.js
 * Vanilla JS (ES6+) for:
 *   1. CountdownTimer  — Live countdown from a data-ends-at ISO timestamp
 *   2. TabController   — Skill carousel category tabs
 *   3. CarouselScroller — Arrow-button driven scroll for each carousel track
 *   4. CardClickRouter  — Makes .sc-card[data-href] fully clickable
 */

// ── 1. Countdown Timer ─────────────────────────────────────────
class CountdownTimer {
  /**
   * @param {string} countdownId  — id of the countdown root element
   * @param {string} hoursId      — id of the hours <span>
   * @param {string} minsId       — id of the minutes <span>
   * @param {string} secsId       — id of the seconds <span>
   */
  constructor ({ countdownId, hoursId, minsId, secsId }) {
    this.root  = document.getElementById(countdownId);
    this.hours = document.getElementById(hoursId);
    this.mins  = document.getElementById(minsId);
    this.secs  = document.getElementById(secsId);
    this.timer = null;
  }

  start () {
    if (!this.root) return;

    const endsAtRaw = this.root.dataset.endsAt;
    if (!endsAtRaw) return;

    const endsAt = new Date(endsAtRaw).getTime();

    const tick = () => {
      const diff = endsAt - Date.now();

      if (diff <= 0) {
        this._update(0, 0, 0);
        clearInterval(this.timer);
        return;
      }

      const h = Math.floor(diff / 3_600_000);
      const m = Math.floor((diff % 3_600_000) / 60_000);
      const s = Math.floor((diff % 60_000) / 1_000);

      this._update(h, m, s);
    };

    tick(); // run immediately to avoid 1-second blank
    this.timer = setInterval(tick, 1_000);
  }

  stop () {
    clearInterval(this.timer);
  }

  _update (h, m, s) {
    const pad = (n) => String(n).padStart(2, '0');
    if (this.hours) this.hours.textContent = pad(h);
    if (this.mins)  this.mins.textContent  = pad(m);
    if (this.secs)  this.secs.textContent  = pad(s);
  }
}

// ── 2. Tab Controller ──────────────────────────────────────────
class TabController {
  /**
   * @param {string} tabsContainerId — id of the tabs wrapper
   */
  constructor (tabsContainerId) {
    this.container = document.getElementById(tabsContainerId);
  }

  init () {
    if (!this.container) return;

    this.container.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-target]');
      if (!btn) return;

      // Deactivate all tabs + panels
      this.container.querySelectorAll('.skill-carousels__tab').forEach(t => {
        t.classList.remove('is-active');
        t.setAttribute('aria-selected', 'false');
      });

      document.querySelectorAll('.skill-carousels__panel').forEach(p => {
        p.classList.remove('is-active');
      });

      // Activate clicked tab + its panel
      btn.classList.add('is-active');
      btn.setAttribute('aria-selected', 'true');

      const panel = document.getElementById(btn.dataset.target);
      if (panel) panel.classList.add('is-active');
    });
  }
}

// ── 3. Carousel Scroller ───────────────────────────────────────
class CarouselScroller {
  /**
   * Binds arrow buttons to scroll their associated track.
   * Arrow buttons must have a data-track="<inner-track-id>" attribute.
   */
  init () {
    document.querySelectorAll('.skill-carousels__arrow').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();

        const trackId = btn.dataset.track;
        const track   = document.getElementById(trackId);
        if (!track) return;

        const isPrev    = btn.classList.contains('skill-carousels__arrow--prev');
        const cardWidth = track.querySelector('.sc-card')?.offsetWidth || 260;
        const gap       = 20;
        const scrollAmt = (cardWidth + gap) * 2; // scroll 2 cards at a time

        track.scrollBy({
          left:     isPrev ? -scrollAmt : scrollAmt,
          behavior: 'smooth',
        });
      });
    });
  }
}

// ── 4. Card Click Router ───────────────────────────────────────
class CardClickRouter {
  /**
   * Makes any element with [data-href] clickable as a full card link.
   * Preserves native middle-click / ctrl+click behaviour by using
   * window.location only for primary left-clicks.
   */
  init () {
    document.querySelectorAll('[data-href]').forEach(card => {
      card.setAttribute('role', 'link');
      card.setAttribute('tabindex', '0');

      card.addEventListener('click', (e) => {
        // Do not hijack clicks on actual <a> or <button> inside the card
        if (e.target.closest('a, button')) return;
        window.location.href = card.dataset.href;
      });

      card.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          window.location.href = card.dataset.href;
        }
      });
    });
  }
}

// ── Bootstrap on DOMContentLoaded ─────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  new CountdownTimer({
    countdownId: 'flash-countdown',
    hoursId:     'cd-hours',
    minsId:      'cd-mins',
    secsId:      'cd-secs',
  }).start();

  new TabController('skill-tabs').init();
  new CarouselScroller().init();
  new CardClickRouter().init();
});

// Turbo compatibility (re-initialise after Turbo page nav)
document.addEventListener('turbo:load', () => {
  new TabController('skill-tabs').init();
  new CarouselScroller().init();
  new CardClickRouter().init();
});
