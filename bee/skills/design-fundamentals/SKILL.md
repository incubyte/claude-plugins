---
name: design-fundamentals
description: "INVOKE THIS SKILL when making UI/UX decisions, designing layouts, writing UI specs, or reviewing visual components. Contains accessibility rules, typography hierarchy, spacing scale, responsive breakpoints, and a visual quality checklist."
---

# Design Fundamentals

Reference principles for any Bee agent producing, evaluating, or documenting UI work. These are universal — the target project's design system provides specific values on top of these.

---

## Priority System

When design concerns conflict, resolve by priority:

| Priority | Category | Severity |
|----------|----------|----------|
| 1 | Accessibility | CRITICAL |
| 2 | Performance | HIGH |
| 3 | Layout & Responsive | HIGH |
| 4 | Typography & Color | MEDIUM |
| 5 | Animation & Transitions | MEDIUM |
| 6 | Style & Visual Polish | LOW |

Accessibility always wins. A beautiful animation that breaks keyboard navigation is a defect, not a feature.

---

## Accessibility

Non-negotiable minimums:

- **Color contrast**: 4.5:1 ratio for normal text, 3:1 for large text (WCAG AA)
- **Touch targets**: 44x44px minimum for interactive elements
- **Focus visibility**: every interactive element must have a visible focus indicator — never remove outline without replacing it
- **ARIA landmarks**: use semantic HTML (`nav`, `main`, `aside`, `footer`) before reaching for ARIA roles
- **Alt text**: meaningful images get descriptive alt text, decorative images get `alt=""`
- **Keyboard navigation**: all interactive elements reachable and operable via keyboard
- **Motion**: respect `prefers-reduced-motion` — disable or reduce animations when set

---

## Typography

Principles, not prescriptions — specific values come from the project's design system.

- **Hierarchy through size and weight, not just bold.** A clear type scale (e.g., 12/14/16/20/24/32px) creates visual hierarchy without relying on color or decoration.
- **Two fonts maximum.** One for headings, one for body. More than two creates visual noise.
- **Line height**: 1.4-1.6 for body text, 1.1-1.3 for headings. Tight line-height on body text hurts readability.
- **Measure (line length)**: 45-75 characters per line for body text. Wider than 75ch requires more line-height.
- **Weight usage**: use weight to create hierarchy (regular for body, semibold for subheadings, bold for headings). Avoid using bold for emphasis in body text — use sparingly.

---

## Spacing

- **Consistent scale**: spacing should follow a scale (e.g., 4px base: 4/8/12/16/24/32/48/64). Random spacing values (13px, 17px, 23px) signal an unintentional design.
- **Spacing creates grouping**: elements that belong together have less space between them than elements that don't (Gestalt proximity principle).
- **Vertical rhythm**: maintain consistent vertical spacing between sections. Headers get more space above than below (they belong to the content that follows).
- **Padding vs margin**: padding for internal space (inside a card), margin for external space (between cards). Consistent usage matters more than which you choose.

---

## Responsive Breakpoints

Common breakpoints for reference:

| Breakpoint | Width | Target |
|-----------|-------|--------|
| Mobile | 375px | Phones (portrait) |
| Tablet | 768px | Tablets, large phones (landscape) |
| Desktop | 1024px | Small laptops, tablets (landscape) |
| Wide | 1440px | Desktop monitors |

- **Mobile-first**: start with the smallest layout and add complexity at larger sizes. Easier to scale up than scale down.
- **Content-driven breakpoints**: if a layout breaks at 920px, add a breakpoint at 920px — don't force content into predefined breakpoints.
- **Test at boundaries**: 375px (smallest common phone), 768px (tablet), 1024px (small laptop), 1440px (desktop).

---

## Visual Quality Checklist

Quick checks before shipping UI work (adapted from ui-ux-pro-max-skill):

- [ ] Color contrast passes WCAG AA (4.5:1 normal, 3:1 large)
- [ ] Touch targets meet 44x44px minimum
- [ ] All interactive elements have visible focus states
- [ ] Icons are SVG (not emoji as UI elements), consistent size
- [ ] Transitions are 150-300ms (fast enough to feel responsive, slow enough to notice)
- [ ] `cursor-pointer` on all clickable non-link elements
- [ ] Layout stable at all breakpoints (375/768/1024/1440px)
- [ ] No horizontal scroll at any breakpoint
- [ ] `prefers-reduced-motion` respected

---

## Applying These Principles

**When documenting a design system** (design-agent):
- Use these principles as the reference frame for what to extract. The accessibility section tells you what to look for in focus styles and contrast. The typography section tells you what font properties matter.

**When writing specs** (spec-builder):
- These principles inform design-aware ACs. "CTA button meets 44x44px touch target minimum" is an AC grounded in this skill.

**When reviewing** (verifier, reviewer):
- Check UI work against the priority system. Accessibility issues are blockers. Style issues are suggestions.