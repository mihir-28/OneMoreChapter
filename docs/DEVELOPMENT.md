# Development notes

## Target and compatibility

Initial target is Kindle Basic 7th generation, touchscreen, 167-ppi monochrome display, firmware 5.12.2.2, KOReader `2026.07.1`, with Bookshelf installed. Verify the installed Bookshelf version before relying on optional integration. EPUB is the only supported format in the first release. PDF and DjVu are out of scope for v1.

KOReader source is pinned at `v2026.07.1`, peeled commit `9192014d8bd82a91dc1012473be0f238dedfdb54`. Keep any local source checkout outside this repository so its Git history cannot appear in the plugin project's IDE or version history. Do not edit the checkout or copy undocumented behavior from a different release without checking the pinned source.

## Plugin contract

Install under `koreader/plugins/onemorechapter.koplugin/`. KOReader discovers external plugins by the `.koplugin` directory suffix. `_meta.lua` provides display metadata; `main.lua` returns a `WidgetContainer` plugin and registers an item with `self.ui.menu:registerToMainMenu(self)`. The plugin sets `is_doc_only = true` so it loads in reader context. Its menu item is enabled only for `.epub` documents.

KOReader 2026.07.1 source inspection confirmed these interfaces:

- `ReaderUI:getCurrentPage()` supplies current rendered page.
- `Document:getPageCount()`, `Document:getCurrentPos()`, and `Document:getToc()` are available through the active document adapter.
- `ReaderToc:fillToc()`, `getTocIndexByPage()`, `getTocTitleByPage()`, and `getNextChapter()` expose the reader's normalized chapter navigation.
- The Statistics module keeps a numeric `avg_time` and `book_read_pages` count for the active book. These are not a stable public API, so access stays inside `modules/stats_adapter.lua`, is feature-detected, and must be checked against the pinned release. Manual seconds-per-page pace covers missing or disabled statistics.
- Chapter ordering uses the active document XPointer against normalized TOC entries. This preserves entries that map to the same rendered page. The optional compact chapter estimate uses KOReader's additional header content hook and refreshes on position updates; the top status line must be enabled.

The statistics plugin already estimates reading time from page pace. One More Chapter's product value is budget-based stopping recommendations with uncertainty, not a duplicate of KOReader's basic remaining-time estimate. Do not mutate `statistics.sqlite3` or change reading position. Displayed ranges use heuristic bands around the expected value: ±20% for high confidence, ±35% for medium, and ±50% for low. These are planning ranges, not statistical confidence intervals. High confidence requires at least 50 current-book pages; medium requires 20–49; lower samples and manual pace are low confidence. The default recommendation reserves 10% of the budget; user can set buffer from 0–50%.

## Implementation gates

1. **API diagnostic:** source inspection confirmed menu, page, TOC, and statistics interfaces. Device load and fallback checks remain.
2. **MVP:** implemented XPointer-ordered TOC boundaries, same-rendered-page handling, book-end fallback, current-book pace estimates, manual pace, preset/custom budgets, heuristic estimate ranges, buffered stop recommendations, and an optional top status-line estimate.
3. **Device validation:** verify boundary choices, pace samples, UI fit, and Kindle behavior before release.
4. **Accuracy and polish:** rolling 7/30-day pace, outlier filtering and smoothing, optional manual words-per-minute, nested/ambiguous TOC rejection, layout-change confidence, page-based fallback when TOC is absent, translations, and on-device performance remain unimplemented.

The current confidence bands are heuristic labels based only on KOReader's current-book sample count. The displayed ±20/35/50% ranges are planning bands, not measured statistical intervals. Automated behavior tests and Kindle validation remain outstanding.

## Device review checklist

- Confirm plugin load, cold start, suspend/resume, and KOReader restart.
- Check touch and physical-key navigation if applicable.
- Check EPUBs with flat, nested, missing, and malformed TOCs; chapters with images; and multiple font settings.
- Check missing, disabled, empty, and locked statistics states.
- Confirm estimates refresh after pagination changes and never move the reading position.
- Check crash.log, refresh artifacts, 167-ppi legibility, and memory behavior.
- Back up settings before device install; confirm folder removal restores normal KOReader operation.

## Release policy

Increment `version` in `_meta.lua` and add the matching `CHANGELOG.md` section. Run regression and packaging checks before tagging. Tag `vX.Y.Z` only after manual Kindle checks pass. The GitHub release workflow rejects a tag that differs from the plugin version and attaches a reproducible ZIP containing the installable plugin directory, README, changelog, and license. Do not publish the local KOReader source snapshot.
