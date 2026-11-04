# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-04

### Added
- Safety guards on screencast requests: a global rate limit, a circuit breaker that disables
  streaming (re-armed by clicking the panel icon) and a 12-window cap per screen

### Changed
- A screen's overlay is now hidden when it has fewer than two windows
- Thumbnails only stream while their screen's overlay is visible

### Fixed
- Panel icon was invisible: the button is now declared as the full representation, like other
  single-item Plasma widgets
- Overlay visibility waits for the window count to settle, so it no longer flaps while windows
  are still being enumerated at shell start

## [0.1.0] - 2026-11-04

First release.

### Added
- One translucent, always-on-top overlay per monitor, listing only that screen's windows
- Live window thumbnails with title and icon; click a tile to focus its window
- Highlight for the focused window
- Thumbnails shrink so the column always fits the screen height
- Retry logic so thumbnails of newly opened windows fill in
- Settings dialog: screen side, thumbnail width, thumbnail and backdrop opacity, column
  position, edge gap and bottom margin
- Panel icon to hide and show the overlays

[Unreleased]: https://github.com/bootswithdefer/plasma-window-overlay/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bootswithdefer/plasma-window-overlay/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bootswithdefer/plasma-window-overlay/releases/tag/v0.1.0
