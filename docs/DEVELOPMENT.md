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
- `ReaderStatistics:getTimeForPages(pages)` returns a formatted estimate when statistics are enabled and a valid average exists. `avg_time` is also present but is internal state; prefer the method and treat it as optional.

The statistics plugin already estimates reading time from page pace. One More Chapter's product value is budget-based stopping recommendations with uncertainty, not a duplicate of KOReader's basic remaining-time estimate. Do not mutate `statistics.sqlite3` or change reading position.

## Implementation gates

1. **API diagnostic:** load plugin in reader, confirm menu entry on EPUB only, inspect page/TOC/statistics interfaces, and verify clear fallback when TOC or statistics are absent.
2. **MVP:** select a reliable next chapter boundary, estimate remaining time with KOReader statistics where usable, and offer a manual pace fallback.
3. **Budget recommendation:** compare current and upcoming chapter boundaries against preset/custom time budgets; show a range and confidence; never navigate without confirmation.
4. **Device polish:** settings, button navigation, translations, error states, low-grayscale readability, and on-device performance.

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
