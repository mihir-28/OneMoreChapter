# One More Chapter

One More Chapter helps readers estimate time to an EPUB chapter boundary and choose a stopping point from a reading-time budget. It runs inside KOReader and works offline.

Development targets Kindle Basic 7th generation with KOReader `2026.07.1`. Current implementation is the API reconnaissance dialog for EPUBs. Chapter estimates, time-budget recommendations, settings, and device-tested support will follow the development gates in [development notes](docs/DEVELOPMENT.md).

## Install for development

Copy the `onemorechapter.koplugin/` folder into `koreader/plugins/` on the device, safely eject, then restart KOReader. Open an EPUB and choose **One More Chapter** from the reader menu. The first build reports the detected page, TOC, and statistics interfaces for API verification.

For an installable release, copy the complete `onemorechapter.koplugin/` folder from the ZIP into `koreader/plugins/`. Remove that folder to uninstall.

## Compatibility

Pinned source: KOReader `v2026.07.1`, commit `9192014d8bd82a91dc1012473be0f238dedfdb54`. This source pin guides development; actual Kindle integration and refresh behavior still require device checks. See the compatibility matrix in [development notes](docs/DEVELOPMENT.md).

## Data and privacy

The plugin is designed to work offline. It does not send book, reading, or device data over a network. The current diagnostic build reads document position, table-of-contents, and available statistics-plugin values; it does not write the statistics database or move the reader position.

## Releases

Releases use version-matched Git tags and a ZIP containing the complete installable plugin folder, README, changelog, and license. Create a release only after the manual Kindle compatibility checklist passes. See [development notes](docs/DEVELOPMENT.md).

## License

GNU Affero General Public License v3.0 only. See [LICENSE](LICENSE).
