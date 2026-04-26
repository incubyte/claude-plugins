---
name: design-fundamentals
description: "This skill should be used when making UI/UX decisions, designing layouts, choosing colors and typography, writing UI specs, or reviewing visual components. Contains the two-path design flow (existing system vs greenfield discovery), accessibility rules, typography pairing, color palette guidance using Sanzo Wada's Dictionary of Color Combinations, spatial composition, anti-generic rules, and visual quality checklist."
---

# Design Fundamentals

Reference principles for any Bee agent producing, evaluating, or documenting UI work. These apply universally — the target project's design system provides specific values on top of these.

---

## Two-Path Design Flow

Before applying any design principle, determine which path you're on:

**Path A — Existing Design System:** The project has design tokens, Tailwind config, CSS custom properties, or a component library. **Follow what exists. Never override. Never suggest alternatives.** Extract, document, and ensure new work is consistent with the established system.

**Path B — Greenfield (No Design System):** No design system detected. Run a design discovery with the developer using question before making any visual decisions. See the Design Discovery section below.

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
- **Color-blind safety**: never rely on color alone to convey meaning. Status indicators (success, error, warning), form validation, charts, and badges must pair color with a secondary signal — icon, label, pattern, or shape. Test against deuteranopia (red-green, ~8% of men) and protanopia.
- **Motion**: respect `prefers-reduced-motion` — disable or reduce animations when set

---

## Design Discovery (Greenfield Only)

When no existing design system is found, discover the developer's intent before proposing anything. Use question for each decision.

### 1. Mood / Tone

Ask: "What visual feel are you going for?"
Options should be contextual to the app, but examples: "Clean & Minimal" / "Bold & Vibrant" / "Warm & Approachable" / "Editorial & Refined"

### 2. Color Palette

Search online for color combinations from **Sanzo Wada's Dictionary of Color Combinations** that match the mood and the app's domain. Sanzo Wada was a Japanese artist who cataloged harmonious color combinations — these palettes are distinctive, curated, and avoid generic AI defaults.

- Search for combinations that fit the mood (e.g., "Sanzo Wada warm earthy combinations" or "Sanzo Wada cool editorial palette")
- Present 3-4 palette options to the developer via question, showing the hex values and a brief description of each palette's character
- The developer picks one, and you derive primary, secondary, accent, and neutral colors from it
- **Always verify contrast**: proposed text/background combinations must pass WCAG AA (4.5:1 for normal text)

### 3. Typography

Ask about font character, not specific font names. The tone informs the pairing:

- **Minimal/Clean**: geometric sans (heading) + humanist sans (body)
- **Editorial/Refined**: serif with character (heading) + clean sans (body)
- **Bold/Vibrant**: strong display font (heading) + readable sans (body)
- **Warm/Approachable**: rounded sans or soft serif (heading) + friendly body font

Present 2-3 specific pairings via question based on the chosen tone. Avoid generic defaults — see Anti-Generic Rules below.

### 4. Component Style

Ask: "What shape language fits your product?"
Options: "Rounded & soft" / "Sharp & geometric" / "Mixed (rounded buttons, sharp cards)"

This informs border-radius, shadow usage, and border style across all components.

### 5. Execution Pattern

The chosen mood maps to concrete CSS patterns. Present this as part of the design brief — it gives the programmer agent specific techniques, not just adjectives.

- **Clean & Minimal**: generous whitespace, subtle `box-shadow` (0 1px 3px rgba(0,0,0,0.08)), thin borders (1px solid), muted backgrounds, no gradients, precision spacing
- **Bold & Vibrant**: saturated colors, layered shadows for depth, noise/grain textures (`background-image: url(noise.svg)`), geometric patterns, strong borders, high-contrast type
- **Warm & Approachable**: soft shadows (0 4px 12px rgba(0,0,0,0.06)), rounded corners (8-16px), warm neutral backgrounds, illustration-friendly layouts, generous padding
- **Editorial & Refined**: dramatic type scale (large headings, small body), generous negative space, minimal color (near-monochrome + one accent), serif headings, strong vertical rhythm

---

## Typography

### Hierarchy

- **Size and weight create hierarchy.** A clear type scale (e.g., 12/14/16/20/24/32px) creates visual hierarchy without relying on color or decoration.
- **Line height**: 1.4-1.6 for body text, 1.1-1.3 for headings.
- **Measure (line length)**: 45-75 characters per line for body text.
- **Weight progression**: regular for body, semibold for subheadings, bold for headings.

### Pairing

- **Two fonts maximum.** One display/heading font, one body font. They should contrast in style but share a visual quality (both geometric, both humanist, etc.)
- **The heading font carries personality.** It can be distinctive and characterful.
- **The body font carries readability.** It should be clean and comfortable at small sizes.

---

## Spatial Composition

### Spacing Scale

- **Consistent scale**: spacing follows a base unit (e.g., 4px: 4/8/12/16/24/32/48/64). Random values (13px, 17px) signal unintentional design.
- **Spacing creates grouping**: elements that belong together have less space between them (Gestalt proximity).
- **Vertical rhythm**: consistent spacing between sections. Headers get more space above than below.

### Grid Systems

Use a structural grid for layout consistency:
- **12-column grid** is the default for web layouts — flexible enough for 1, 2, 3, 4, or 6 column arrangements
- **CSS Grid or Flexbox** — use Grid for two-dimensional layouts (rows + columns), Flexbox for one-dimensional flow
- **Max-width container** — constrain content width (e.g., `max-width: 1200px; margin: 0 auto`) to prevent lines from stretching on wide screens
- **Gutter consistency** — use the spacing scale for gutters (e.g., 16px or 24px). Don't mix gutter sizes within the same layout level.
- **Grid-breaking elements** draw attention. A full-bleed image, an oversized heading, or an element that overlaps its container — used sparingly, these create memorable moments.

### Layout

- **Generous negative space** signals confidence and clarity. Don't fill every pixel.
- **Asymmetry is intentional.** Centered layouts are safe but predictable. Off-center compositions, unequal columns, and staggered grids create visual interest when done deliberately.
- **Density matches context.** Data-heavy dashboards need density. Marketing pages need breathing room. Match spatial treatment to what the content demands.

---

## Progressive Disclosure

Manage cognitive load by showing less and revealing more on demand. This applies to any UI with moderate-to-high information density.

- **Show the essential, hide the rest.** Settings pages, dashboards, and complex forms benefit from collapsible sections, tabs, or "show advanced" toggles.
- **Prioritize by frequency of use.** The most common actions should be visible. Rare actions go behind a menu or expandable section.
- **Multi-step over mega-form.** A wizard/stepper with 3 focused steps beats a single page with 20 fields. Each step should feel completable.
- **Progressive detail in data.** Tables and lists show summary rows; clicking reveals detail. Cards show headline + key metric; expanding shows the full picture.
- **Don't hide critical actions.** Save, submit, delete, and primary CTAs should always be visible — never behind a disclosure pattern.

---

## Color & Theme

- **60-30-10 distribution**: apply your palette with intention — 60% dominant color (backgrounds, large surfaces), 30% secondary (cards, sections, supporting elements), 10% accent (CTAs, highlights, active states). This prevents the "everything is the same color" problem and gives the accent real impact.
- **Dominant + accent**: a strong primary color with a sharp accent outperforms timid, evenly-distributed palettes.
- **Use CSS variables** for all color values. Never hardcode hex values in components.
- **Semantic colors**: define success, warning, error, info independently from brand palette.
- **Dark/light considerations**: if the app needs both themes, design the token system for it from the start — not as an afterthought.

---

## Motion & Interaction

- **Transitions**: 150-300ms for UI feedback (fast enough to feel responsive, slow enough to notice).
- **High-impact moments**: one well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.
- **Hover and focus states**: every interactive element should respond to hover and show clear focus. These aren't optional polish — they're usability.
- **Prefer CSS-only** for simple transitions. Reach for animation libraries only for complex orchestration.
- **Respect `prefers-reduced-motion`**: disable or simplify all animations when set.

---

## Anti-Generic Rules

Avoid these common AI defaults that make every project look the same:

- **Fonts**: Do not default to Inter, Roboto, Arial, or system fonts for every project. Choose fonts that match the project's personality.
- **Colors**: Do not default to purple gradients on white backgrounds, or blue-to-purple hero sections. Derive colors from the design discovery or existing system.
- **Layouts**: Do not default to centered card grids, hero-with-CTA-below, or three-column feature sections unless the content specifically calls for them.
- **Components**: Do not default to the same rounded-corner cards with subtle shadows everywhere. Match component style to the project's shape language.
- **Variety**: No two projects should look the same. The design discovery exists to produce context-specific choices, not to converge on safe defaults.

---

## Responsive Breakpoints

| Breakpoint | Width | Target |
|-----------|-------|--------|
| Mobile | 375px | Phones (portrait) |
| Tablet | 768px | Tablets, large phones (landscape) |
| Desktop | 1024px | Small laptops, tablets (landscape) |
| Wide | 1440px | Desktop monitors |

- **Mobile-first**: start with the smallest layout and add complexity at larger sizes.
- **Content-driven breakpoints**: if a layout breaks at 920px, add a breakpoint at 920px.
- **Test at boundaries**: 375px, 768px, 1024px, 1440px.

---

## Visual Quality Checklist

Quick checks before shipping UI work:

- [ ] Color contrast passes WCAG AA (4.5:1 normal, 3:1 large)
- [ ] Touch targets meet 44x44px minimum
- [ ] All interactive elements have visible focus states
- [ ] All interactive elements respond to hover
- [ ] Icons are SVG (not emoji as UI elements), consistent size
- [ ] Transitions are 150-300ms
- [ ] `cursor-pointer` on all clickable non-link elements
- [ ] Layout stable at all breakpoints (375/768/1024/1440px)
- [ ] No horizontal scroll at any breakpoint
- [ ] `prefers-reduced-motion` respected
- [ ] Colors use CSS variables, not hardcoded hex
- [ ] Color is never the only signal for status (icons/labels alongside)
- [ ] Content constrained by max-width container — no full-width text on wide screens
- [ ] Complex forms/settings use progressive disclosure (tabs, steppers, collapsible sections)
- [ ] Font pairing is intentional and consistent

---

## Applying These Principles

**When running design discovery** (design-agent, greenfield path):
- Follow the Design Discovery flow: mood → Sanzo Wada palette search → typography pairing → component style. Use question for every decision.

**When documenting an existing design system** (design-agent, existing path):
- Use the accessibility, typography, and spacing sections as the reference frame for what to extract. Never suggest alternatives to what exists.

**When writing specs** (spec-builder):
- These principles inform design-aware ACs. "CTA button meets 44x44px touch target minimum" is an AC grounded in this skill.

**When coding UI** (programmer):
- Follow the anti-generic rules. Use CSS variables. Match the design brief. If no brief exists, flag it — don't invent a design system on the fly.

**When reviewing** (verifier, reviewer):
- Check UI work against the priority system. Accessibility issues are blockers. Style issues are suggestions.
