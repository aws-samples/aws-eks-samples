---
inclusion: auto
name: creating-samples
description: Use when creating, adding, renaming, or removing a sample under examples/ (eksctl, kubernetes, helm). Covers publishing the sample to the GitHub Pages site in docs/ and keeping the landing page sample counts accurate.
---

# Creating samples

A sample is not done until it is on the GitHub Pages site. Every change that adds, renames, or removes a sample under `examples/` MUST update `docs/` in the same commit or PR.

## How the site is built

The site is hand-written static HTML in `docs/`. `docs/.nojekyll` disables Jekyll, so these files are exactly what GitHub Pages serves:

- `docs/index.html`: landing page (hero metrics, stats bar, category cards)
- `docs/eksctl/index.html`, `docs/kubernetes/index.html`, `docs/helm/index.html`: one page per category
- `docs/assets/css/style.css`: shared styles

`docs/index.md`, `docs/_config.yml`, and `docs/examples/**/index.md` are legacy Jekyll files and are not rendered. Keep the sample tables in `docs/examples/<category>/index.md` in sync anyway so they don't drift.

## What counts as a sample

One sample is one direct subfolder of `examples/<category>/`, where category is `eksctl`, `kubernetes`, or `helm`. Name it `how-to-<topic>` in kebab-case and include a `README.md` with prerequisites, steps, and cleanup. Files at the category root (like `examples/kubernetes/README.md`) are not samples.

## Checklist

### 1. Add a card to the category page

In `docs/<category>/index.html`:

- Append a new `ex-card` as the last child of `<div class="examples-grid">`, using the template below.
- Set `ex-card-num` to the next number, zero-padded to two digits (`07`, `12`). Use the same number in the HTML comment above the card.
- Point `href` at `https://github.com/aws-samples/aws-eks-samples/tree/main/examples/<category>/<sample-folder>` and keep `target="_blank" rel="noopener"`.
- Title: short and human-readable, not the folder name. Escape `&` as `&amp;`.
- Description: 1 to 2 sentences on what the sample deploys and the problem it solves. Use `<strong>` and `<code>` sparingly, like the existing cards.
- Add 3 to 5 `svc-tag`s naming the main AWS services and Kubernetes features.
- Update `<div class="examples-section-title">N Examples</div>` to the new card count.
- If the sample introduces a headline technology not already in `.cat-hero-tags`, add a `cat-tag` for it.

```html
    <!-- 12: Short Title -->
    <a href="https://github.com/aws-samples/aws-eks-samples/tree/main/examples/kubernetes/how-to-example" target="_blank" rel="noopener" class="ex-card ex-card--kubernetes">
      <div class="ex-card-top">
        <h3>Short Title</h3>
        <span class="ex-card-num">12</span>
      </div>
      <p>
        One or two sentences describing what the sample deploys and the problem it solves.
      </p>
      <div class="ex-card-tags">
        <span class="svc-tag">Service A</span>
        <span class="svc-tag">Service B</span>
        <span class="svc-tag">Feature C</span>
      </div>
      <span class="ex-card-link">
        View sample
        <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="3" y1="8" x2="13" y2="8"/><polyline points="8 3 13 8 8 13"/>
        </svg>
      </span>
    </a>
```

Match the modifier class to the page: `ex-card--eksctl`, `ex-card--kubernetes`, or `ex-card--helm`.

### 2. Update the landing page metrics

Recount from the filesystem every time (see Verify). Don't add 1 to whatever the page currently shows, because an earlier miss would carry forward.

In `docs/index.html`:

| Element | Section | Value |
|---|---|---|
| `.hero-meta-value` above the `Samples` label | hero | Total samples across all categories, followed by `+` (16 becomes `16+`) |
| `.stat-num` above the `Samples` label | stats bar | Same value as the hero |
| `.cat-card-badge` in that category's `cat-card` | category grid | `N Samples` for that category (`1 Sample` when singular) |
| `.stat-num` above `AWS Services` | stats bar | Bump only if the sample uses AWS services no other sample covers. Keep the `N+` format |
| `.hero-meta-value` and `.stat-num` above `Categories` | hero and stats bar | Change only when a category is added or removed |

Optional: if the sample's headline technology is missing from that category card's `.cat-card-tags` or `.cat-card-desc`, add it. Keep each card to about 5 tags.

### 3. Sync the legacy table

Add a row to the table in `docs/examples/<category>/index.md`:

```markdown
| [Short Title](how-to-example/) | One-line description |
```

## Special cases

- First Helm sample: in `docs/helm/index.html`, replace the `<div class="coming-soon-wrap">` block with a `<section class="examples-section">` that mirrors `docs/kubernetes/index.html` and uses `ex-card--helm`, and drop "coming soon" from its `<meta name="description">`. On the landing page Helm card, change the badge from `Coming soon` to `1 Sample`, the CTA text from `Preview &amp; contribute` to `Explore Samples`, and remove "actively being expanded" from the description.
- Removing or renaming a sample: delete or update its card, fix the `href`, renumber the remaining `ex-card-num` values and comments so they stay sequential, and redo step 2.
- New category: this needs a new category page, nav and footer links on every page, a landing card, and new color modifier classes in `style.css`. Confirm with the user before adding one.

## Verify

Run from the repo root before finishing:

```bash
total=0
for c in eksctl kubernetes helm; do
  n=$(find "examples/$c" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  cards=$(grep -c 'class="ex-card ex-card--' "docs/$c/index.html")
  echo "$c: folders=$n cards=$cards"
  total=$((total + n))
done
echo "total samples: $total"
grep -n 'examples-section-title' docs/*/index.html
grep -n -A1 'hero-meta-value\|class="stat-num"\|cat-card-badge' docs/index.html | grep -v '^--$'
```

All of these must agree:

- For each category, `folders`, `cards`, `examples-section-title`, and the landing `cat-card-badge` show the same number.
- Both landing `Samples` values equal `<total>+`.

To preview locally, the user can run `python3 -m http.server 8000 --bind 127.0.0.1 --directory docs` and open http://127.0.0.1:8000. Keep the bind on loopback.
