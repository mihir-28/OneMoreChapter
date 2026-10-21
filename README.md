# One More Chapter

One More Chapter helps you choose a chapter stopping point that fits the time you have. Open it from KOReader while reading an EPUB to see an estimate for the current chapter boundary and the next boundary. Choose a time budget, then use the suggested stopping point to decide whether to keep reading. The plugin never turns pages or changes your reading position.

Estimates use KOReader's current-book seconds-per-page pace when available. You can enter a manual pace if KOReader has not collected enough reading data. Estimates are approximate: the plugin shows a range and a low, medium, or high confidence label. Those ranges are planning guides, not statistical confidence intervals.

## Requirements

- KOReader `2026.07.1` for the pinned development target.
- An EPUB with a usable table of contents for chapter estimates.
- KOReader's Statistics plugin enabled and some recorded pages for automatic pace estimates. Manual pace works when automatic pace is unavailable.
- Kindle Basic 7th generation is the primary device target. Other devices and KOReader versions have not been validated yet.

The plugin works offline. It does not require Bookshelf, network access, or a separate service.

## Install on Kindle

1. Download `onemorechapter-v0.1.0.zip` from [GitHub Releases](https://github.com/mihir-28/OneMoreChapter/releases/latest) to your computer.
2. Connect your Kindle by USB. Back up `koreader/settings/` before changing files.
3. Extract the ZIP. Copy the complete `onemorechapter.koplugin/` folder into `koreader/plugins/` on the Kindle. The final path should be `koreader/plugins/onemorechapter.koplugin/main.lua`.
4. Safely eject the Kindle, then restart KOReader.
5. Open an EPUB. Open the reader menu, go to **Tools → One More Chapter**, and follow the prompts.

Do not copy the ZIP itself into `koreader/plugins/`. The extracted plugin folder must sit directly inside that directory.

## First use

The plugin is listed first in the reader's **Tools** tab in KOReader's default menu order. The opening screen shows the current chapter, an estimate to its next table-of-contents boundary, and the following chapter when available. Select a preset budget of 10, 15, 20, or 30 minutes, or enter a custom budget from 1 to 480 minutes.

When KOReader's top status line is enabled, the plugin shows a compact **Ch: 12-18m** estimate there. It refreshes as you turn pages; at a chapter's first page, the estimate is for the whole chapter. Toggle this from the budget screen with **Show/Hide chapter time in header**. The header stays empty if pace or a future chapter boundary is unavailable.

If KOReader has pace data for the current book, the plugin uses it automatically. If it has no usable pace, the plugin asks for a manual average in seconds per rendered page. You can also choose **Set manual pace** from the budget screen. To return to automatic pace later, choose **Use KOReader automatic pace**.

The default safety buffer reserves 10% of your budget. Change it from **Set safety buffer**; allowed values are 0–50%. The plugin saves your pace choice, manual pace, safety buffer, and last custom budget in KOReader settings.

When no future chapter boundary fits, the plugin shows the next boundary and explains that it is unlikely or too tight for the budget. It may use the end of the book as a final stopping point. It never moves to that point for you.

## Test on your Kindle

Try these checks with a few EPUBs before relying on estimates. Keep your current page in view so you can confirm that opening and closing the plugin does not change it.

### Basic flow

- Open an EPUB with a clear, multi-chapter table of contents. Open **One More Chapter** from the reader menu.
- Confirm **One More Chapter** appears on the first page of the **Tools** tab in KOReader's default menu order.
- Confirm the current chapter and time to the next boundary appear. If another boundary exists, confirm its title and estimate appear too.
- Select each preset budget, then try a custom value such as 7 minutes.
- Confirm the result names a stopping boundary and gives an estimate range, confidence label, and budget fit.
- Close the dialog and verify KOReader remains at the same page. Reopen the plugin and confirm it refreshes from your current position.

### Pace and settings

- On a book with no recorded pace, choose a manual pace such as 60 seconds per page. Confirm the result says it is using manual pace and shows low confidence.
- With automatic pace selected (the default), open a budget and confirm the result uses KOReader pace and reports its confidence. If there is no usable data, the plugin should request manual pace. To check switching back, set a manual pace first, then choose **Use KOReader automatic pace**.
- Change the safety buffer to 0%, then 50%. Compare the suggested boundary; a larger buffer should not make the plugin recommend a later boundary.
- Restart KOReader. Confirm saved pace and buffer choices remain available.
- With KOReader's top status line enabled, confirm the **Ch: ...** estimate appears and changes as you turn pages. Toggle it off and on from the plugin's budget screen.

### EPUB and layout edge cases

- Try an EPUB with nested chapters and one with a flat table of contents. Check that chapter titles and boundaries look plausible.
- Try an EPUB without a usable table of contents. The plugin should show a clear boundary-unavailable message and remain usable after closing it.
- Try an EPUB near its last chapter. Confirm the end-of-book boundary appears where available.
- Change font size or margins, reopen the plugin, and check that estimates use the updated rendered-page layout.
- Open a PDF or another unsupported format. One More Chapter should not be enabled for it.
- Reopen the dialog several times, suspend and resume the Kindle, and restart KOReader. Watch for crashes, stale values, or slow redraws.

### Record a test issue

For an issue, note your Kindle model, KOReader version, EPUB type (no book file needed), whether automatic or manual pace was selected, the current page, the displayed range, and the steps to reproduce. A screenshot of the plugin screen can help. Do not share copyrighted book files or personal reading databases.

If KOReader reports a crash, copy its `crash.log` from the KOReader folder on the Kindle and include the relevant lines. Remove personal paths or other private details before posting logs publicly.

## Troubleshooting

- **Menu item missing or disabled:** Confirm KOReader is open in an `.epub` document, the folder is named `onemorechapter.koplugin`, and it is directly under `koreader/plugins/`. Restart KOReader after copying files.
- **Chapter boundary unavailable:** This EPUB may lack a usable table of contents or have TOC positions KOReader cannot map to rendered pages. Chapter prediction currently requires a future TOC boundary; page-based fallback is not implemented.
- **Manual pace prompt appears:** KOReader may have no recorded pages for this book or its Statistics plugin may be disabled. Enter seconds per rendered page, or enable Statistics and read some pages before trying automatic pace again.
- **Estimate seems wrong after changing font size:** Reopen the plugin to refresh it. If it remains wrong, record the old and new font settings and the page shown.
- **Plugin fails to load:** Check `crash.log`, confirm every file from the ZIP was extracted, then remove the plugin folder to restore KOReader without it.

## Remove

Close KOReader or return to USB storage, then delete `koreader/plugins/onemorechapter.koplugin/`. Restart KOReader. The plugin does not change reading progress or the Statistics database. Its saved preferences remain in KOReader settings unless you remove them separately.

## Compatibility and limitations

Development is pinned to KOReader `v2026.07.1`, commit `9192014d8bd82a91dc1012473be0f238dedfdb54`. See [development notes](docs/DEVELOPMENT.md) for the compatibility matrix, architecture, and remaining validation work.

The current release supports EPUB only. It uses KOReader's current-book average pace and page distance to TOC boundaries. Pace calibration does not yet use rolling 7- or 30-day history, outlier filtering, or layout-change confidence. Missing or ambiguous TOCs do not have a page-based chapter fallback. Automatic word counting and manual words-per-minute are not implemented.

## Data and privacy

- Works offline and sends no book, reading, or device data over a network.
- Reads the active document's page and TOC state plus KOReader's in-memory page-pace estimate.
- Does not query or write `statistics.sqlite3`, read book contents, or change reading position.
- Saves plugin preferences through KOReader settings.

## Repository layout

```text
onemorechapter.koplugin/
  _meta.lua                   Plugin metadata
  main.lua                    KOReader plugin entry point
  modules/
    chapter_adapter.lua       EPUB table-of-contents boundaries
    estimator.lua             Pace ranges and budget recommendations
    settings.lua              Plugin preferences
    stats_adapter.lua         KOReader and manual pace inputs
    ui.lua                    Reader dialogs and budget controls
docs/
  DEVELOPMENT.md              Architecture and device checklist
.github/workflows/
  release.yml                 Versioned release packaging
  test.yml                    Lua syntax check
scripts/
  package_release.py           Reproducible install ZIP builder
  release_notes.py             Changelog release notes
CHANGELOG.md
LICENSE
README.md
```

## Releases

Version-matched Git tags create GitHub Releases with an install ZIP containing the complete plugin folder, this README, changelog, and license. See [all releases](https://github.com/mihir-28/OneMoreChapter/releases). Release tags follow `vX.Y.Z` and must match the version in `_meta.lua`.

## License

GNU Affero General Public License v3.0 only. See [LICENSE](LICENSE).

## Upstream projects

- [KOReader](https://github.com/koreader/koreader)
- [KOReader Statistics plugin](https://github.com/koreader/koreader/tree/master/plugins/statistics.koplugin)
