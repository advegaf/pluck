# Pluck

Hold-click to copy, anywhere on macOS 26.

Select text in any app, press down on the selection, keep the mouse still for
~150 ms, release. The text is now on your clipboard. A tiny "✓ Copied" pill
confirms near the cursor. The click's native behavior (deselect, caret move)
proceeds unchanged.

No modifier key. No floating UI. Just a gesture.

## Why

Terminals and several Linux desktops let you "select, click, copied". macOS
has never shipped an equivalent. Existing tools are either floating action
bars (PopClip), copy-on-every-select (macpaste), or clipboard history
managers. Pluck is neither.

## Install

Requires macOS 14+ (built against macOS 26 / Xcode 26).

```sh
make bundle
open build/Pluck.app
```

The first launch walks you through two system permissions:

- **Accessibility** — so Pluck can read the selected text from the window you
  click in.
- **Input Monitoring** — so Pluck can observe (not intercept) your mouse
  events.

## How it decides to fire

1. You mouse-down somewhere.
2. If you drag, Pluck stays out of the way — you're selecting.
3. If you release in under 150 ms, Pluck stays out of the way — you were
   clicking normally.
4. If you hold still for 150 ms+, Pluck reads the selected text via the
   Accessibility API, writes it to the clipboard, and shows a pill near the
   cursor.
5. Your click finishes naturally: selection clears, caret moves.

If the app doesn't expose its selection via the Accessibility API (many
Electron apps, some Chromium embeds), Pluck transparently synthesizes a
Cmd+C, keeps the result if the clipboard changed, and restores the previous
clipboard otherwise.

## Configure

Menu bar → **Preferences…**

- **Hold delay** — 100–400 ms, default 150 ms.
- **HUD** — toggle the "Copied" pill.
- **Launch at login** — via `SMAppService`.
- **Blocklist** — apps where Pluck stays silent. Ships with sane defaults
  (Figma, Sketch, Photoshop, Illustrator, Blender, Unity, Unreal, Excel,
  Numbers, Finder, Xcode Interface Builder).

## Develop

```sh
swift build           # compile
swift test            # unit tests
make bundle           # assemble Pluck.app (adhoc signed)
make run              # build, sign, launch
make clean            # wipe build artifacts
```

Layout:

```
Sources/Pluck/
  PluckApp.swift            # @main, MenuBarExtra + Settings scenes
  AppShell.swift            # wires engine → reader → HUD
  Engine/
    GestureStateMachine.swift   # pure state machine (testable)
    GestureEngine.swift         # CGEventTap wrapper
    AXSelectionSource.swift     # reads kAXSelectedTextAttribute
    Pasteboard.swift            # NSPasteboard abstraction
    KeystrokeSender.swift       # Cmd+C synthesis
    SelectionReader.swift       # AX → Cmd+C fallback orchestration
  HUD/
    CopiedPill.swift            # SwiftUI pill
    HUDGeometry.swift           # pure positioning math
    HUDPresenter.swift          # NSPanel lifecycle
  Prefs/
    PrefsView.swift
    Blocklist.swift
  Onboarding/
    PermissionChecks.swift
    OnboardingWindow.swift
  Resources/
    Info.plist
    entitlements.plist
Tests/PluckTests/
  GestureStateMachineTests.swift
  SelectionReaderTests.swift
  HUDGeometryTests.swift
  BlocklistTests.swift
```

## Design

`DESIGN.md` is generated from `npx getdesign@latest add apple` and drives the
look of the HUD pill, preferences window, and onboarding. It's a spec for AI
coding agents — it has no runtime role.

## License

MIT. See [LICENSE](LICENSE).
