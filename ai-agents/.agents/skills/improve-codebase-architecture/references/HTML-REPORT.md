# HTML Report Format

The architectural review is rendered as a single self-contained HTML file in the OS temp directory. All styling is inline CSS from [report.css](report.css); there is no stylesheet or CSS-generating script from a network. Hand-built divs and inline SVG carry the diagrams. Mermaid (CDN) is an optional extra for graph-shaped diagrams; don't lean on it for everything, it'll start to look generic, and never make the report depend on it.

## Why no Tailwind CDN

`cdn.tailwindcss.com` is the Play CDN: it ships a JS compiler that scans the DOM and generates CSS in the browser. If that one request is blocked, slow, or fails (VPN, corporate proxy, offline), the report renders with no CSS at all. Static CSS inlined in `<style>` cannot fail this way.

## Scaffold

Copy the contents of [report.css](report.css) into the `<style>` element below, then append report-specific rules.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Architecture review – {{repo name}}</title>
    <style>
      /* contents of references/report.css, verbatim */
      /* report-specific rules below */
    </style>
    <!-- Optional: only when at least one diagram is a Mermaid graph. -->
    <script type="module">
      try {
        const { default: mermaid } = await import("https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs");
        mermaid.initialize({ startOnLoad: false, theme: "neutral", securityLevel: "loose" });
        await mermaid.run({ querySelector: "pre.mermaid" });
      } catch (e) {
        console.warn("mermaid unavailable, diagram source is shown as text", e);
      }
    </script>
  </head>
  <body>
    <main>
      <header class="stack">...</header>
      <section id="candidates" class="stack">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

If Mermaid fails to load, `pre.mermaid` stays as readable source text. Omit the `<script>` entirely when no diagram uses Mermaid.

## Class vocabulary (from report.css)

`stack`, `card`, `card-head`, `badge` + `badge-strong|badge-worth|badge-speculative`, `label`, `muted`, `legend` with `sw-module|sw-seam|sw-leak|sw-deep`, `files`, `ba` + `ba-pane` (before/after), `module`, `module-shallow`, `deep`, `seam`, `leak`, `band` + `band-name|band-note` with `band-ok|band-warn|band-bad`, `mass` + `mass-iface|mass-impl`, `adr`, `wins`. Add a rule after the stylesheet for anything missing instead of reaching for a CDN.

## Header

Repo name, date, and a compact legend: solid box = module, dashed line = seam, red arrow = leakage, thick dark box = deep module. No introduction paragraph — straight into the candidates.

## Candidate card

The diagrams carry the weight. Prose is sparse, plain, and uses the glossary terms ([LANGUAGE.md](LANGUAGE.md)) without ceremony.

Each candidate is one `<article>`:

- **Title** — short, names the deepening (e.g. "Collapse the Order intake pipeline").
- **Badge row** — recommendation strength (`badge-strong` = emerald, `badge-worth` = amber, `badge-speculative` = slate), plus a tag for the dependency category (`in-process`, `local-substitutable`, `ports & adapters`, `mock`).
- **Files** — monospaced list, `<ul class="files">`.
- **Before / After diagram** — the centrepiece. Two columns, side by side. See patterns below.
- **Problem** — one sentence. What hurts.
- **Solution** — one sentence. What changes.
- **Wins** — bullets, ≤6 words each. e.g. "Tests hit one interface", "Pricing logic stops leaking", "Delete 4 shallow wrappers".
- **ADR callout** (if applicable) — one line in an amber-tinted box.

No paragraphs of explanation. If the diagram needs a paragraph to be understood, redraw the diagram.

## Diagram patterns

Pick the pattern that fits the candidate. Mix them. Don't make every diagram look the same — variety is part of the point.

### Mermaid graph (the workhorse for dependencies / call flow)

Use a Mermaid `flowchart` or `graph` when the point is "X calls Y calls Z, and look at the mess." Wrap it in a `ba-pane` card so it doesn't feel parachuted in. Style with classDef to colour leakage edges red and the deep module dark. Sequence diagrams work well for "before: 6 round-trips; after: 1."

```html
<div class="ba-pane">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Hand-built boxes-and-arrows (when Mermaid's layout fights you)

Modules as `<div>`s with borders and labels. Arrows as inline SVG `<line>` or `<path>` elements positioned absolutely over a relative container. Reach for this when you want the "after" diagram to feel like one thick-bordered deep module with greyed-out internals — Mermaid won't render that with the right weight.

### Cross-section (good for layered shallowness)

Stack `band` rows (`band-ok|band-warn|band-bad` sets the left-border colour) to show layers a call passes through. Before: 6 thin layers each doing nothing. After: 1 thick band labelled with the consolidated responsibility.

### Mass diagram (good for "interface as wide as implementation")

Two rectangles per module — one for interface surface area, one for implementation. Before: interface rectangle is nearly as tall as the implementation rectangle (shallow). After: interface rectangle is short, implementation rectangle is tall (deep).

### Call-graph collapse

Before: a tree of function calls rendered as nested boxes. After: the same tree collapsed into one box, with the now-internal calls shown faded inside it.

## Style guidance

- Lean editorial, not corporate-dashboard. Generous whitespace. Headings are serif by default in `report.css`.
- Colour sparingly: one accent (emerald or indigo) plus red for leakage and amber for warnings.
- Keep diagrams ~320px tall so before/after sits comfortably side by side without scrolling.
- Use the `label` class (small uppercase, letter-spaced) for module labels inside diagrams — they should read as schematic, not as UI.
- The only script is the optional Mermaid ESM import. No stylesheet or CSS-generating script comes from a network; the report is otherwise static, with no app code and no interactivity beyond Mermaid's own rendering.

## Top recommendation section

One larger card. Candidate name, one sentence on why, anchor link to its card. That's it.

## Tone

Plain English, concise — but the architectural nouns and verbs come straight from [LANGUAGE.md](LANGUAGE.md). Concision is not an excuse to drift.

**Use exactly:** module, interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality.

**Never substitute:** component, service, unit (for module) · API, signature (for interface) · boundary (for seam) · layer, wrapper (for module, when you mean module).

**Phrasings that fit the style:**

- "Order intake module is shallow — interface nearly matches the implementation."
- "Pricing leaks across the seam."
- "Deepen: one interface, one place to test."
- "Two adapters justify the seam: HTTP in prod, in-memory in tests."

**Wins bullets** name the gain in glossary terms: *"locality: bugs concentrate in one module"*, *"leverage: one interface, N call sites"*, *"interface shrinks; implementation absorbs the wrappers"*. Don't write *"easier to maintain"* or *"cleaner code"* — those terms aren't in the glossary and don't earn their place.

No hedging, no throat-clearing, no "it's worth noting that…". If a sentence could be a bullet, make it a bullet. If a bullet could be cut, cut it. If a term isn't in [LANGUAGE.md](LANGUAGE.md), reach for one that is before inventing a new one.
