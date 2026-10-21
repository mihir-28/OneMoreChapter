# One More Chapter

One More Chapter helps readers estimate time to an EPUB chapter boundary and choose a stopping point from a reading-time budget. It runs inside KOReader and works offline.

Development targets Kindle Basic 7th generation with KOReader `2026.07.1`. The current implementation reads upcoming EPUB TOC boundaries, estimates chapter time from KOReader's current-book page pace, and suggests a stopping chapter for preset or custom time budgets. Estimates show a range and confidence label. Manual seconds-per-page pace is available when KOReader statistics are unavailable or when readers choose manual pace.

## Install for development

Copy the `onemorechapter.koplugin/` folder into `koreader/plugins/` on the device, safely eject, then restart KOReader. Open an EPUB and choose **One More Chapter** from the reader menu. Choose a 10, 15, 20, or 30 minute budget, or enter a custom budget. The plugin suggests a chapter boundary and never changes reading position.

For an installable release, copy the complete `onemorechapter.koplugin/` folder from the ZIP into `koreader/plugins/`. Remove that folder to uninstall.

## Compatibility

Pinned source: KOReader `v2026.07.1`, commit `9192014d8bd82a91dc1012473be0f238dedfdb54`. This source pin guides development; actual Kindle integration and refresh behavior still require device checks. See the compatibility matrix in [development notes](docs/DEVELOPMENT.md).

## Data and privacy

The plugin works offline. It sends no book, reading, or device data over a network. It reads the active document's page and TOC state plus KOReader's in-memory page-pace estimate. It does not query or write `statistics.sqlite3`, read book contents, or change reading position.

## Releases

Releases use version-matched Git tags and a ZIP containing the complete installable plugin folder, README, changelog, and license. Create a release only after the manual Kindle compatibility checklist passes. See [development notes](docs/DEVELOPMENT.md).

## License

GNU Affero General Public License v3.0 only. See [LICENSE](LICENSE).
