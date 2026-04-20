# Changelog

All notable changes to Pluck are documented here. Pluck follows
[Semantic Versioning](https://semver.org).

## [0.1.0] — 2026-04-19

The first public release. Pluck is a free macOS 26 menu-bar utility
that auto-copies selected text when you hold a click on it.

### What you can do

- Select text in any app, press down on it, keep still for ~150 ms,
  release — the text is on your clipboard. A Liquid Glass "✓ Copied"
  pill morphs in near the cursor. The click's native behavior proceeds
  unchanged.
- Tune the hold delay in Preferences (100–400 ms, default 150 ms).
- Add apps to a blocklist where Pluck should stay silent. Ships with
  Figma, Sketch, Photoshop, Illustrator, Blender, Unity, Unreal, Excel,
  Numbers, Xcode IB, and Finder excluded by default.
- Pause/resume from the menu bar. Preferences reachable via ⌘,.
- Launch at login via `SMAppService`.

### How it's built

- Single-process macOS app on Swift 6.2 / Swift Package Manager, no Xcode
  project required. `make install` for an adhoc dev build, `make dmg` for
  a signed + notarized release.
- Selection reading is AX-only via the system-wide focused UI element
  (`kAXFocusedUIElementAttribute`) with a bounded parent walk. No Cmd+C
  synthesis — earlier builds had a fallback that made every click in a
  non-text element play the macOS Funk beep. Dropped entirely.
- Gesture engine is a `CGEventTap` in listen-only mode driven by a pure
  `GestureStateMachine` with a 4 pt drag slop (hand-tremor tolerance) and
  a 150 ms hold threshold. State machine reset on `tapDisabledBy*` events
  so a slow AX read never wedges the engine.
- HUD is a SwiftUI Liquid Glass pill (`.glassEffect`) hosted in a
  click-through `NSPanel`. Quadrant-aware positioning kisses the cursor
  regardless of screen corner; rapid-repeat fires extend the hold rather
  than restart the morph.
- Preferences window is a fixed 700×500 sidebar-plus-content layout with
  native macOS semantic colors (`windowBackgroundColor`,
  `controlBackgroundColor`, `labelColor`). Apple Blue accent, no other
  chromatic color. Press feedback on every button (scale 0.97, 120 ms,
  honors Reduce Motion).
- Onboarding continuity: a persisted `pluck.onboardingCompleted` flag in
  UserDefaults ensures the setup window reappears on the next launch if
  you quit before clicking "Start using Pluck", even after macOS's
  required quit-and-reopen cycle on permission grants.
- App icon is a macOS 26 `.icon` bundle (Icon Composer) with a light
  scissors tile — opts out of the default Liquid Glass icon template in
  Finder/Dock. `.icns` fallback is also shipped.
- 25 passing unit tests across gesture state, selection reading, HUD
  geometry, and blocklist semantics.

### Release artifact

- `Pluck-0.1.0.dmg` (5.2 MB)
- Signed: Developer ID Application: Angel Vega Figueroa (DV483F72N3)
- Notarized and stapled by Apple; Gatekeeper returns
  `source=Notarized Developer ID`.
- sha-256: `d5bf21ad32573f8eb4b00790f7ef1e3ebd76e6794196c0efa1731453edc6f370`

### Requirements

- macOS 26 (the HUD uses Apple's Liquid Glass effects which are 26+
  only).
- Accessibility and Input Monitoring permissions granted on first
  launch.

[0.1.0]: https://github.com/advegaf/pluck/releases/tag/v0.1.0
