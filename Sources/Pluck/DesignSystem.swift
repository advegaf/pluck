import SwiftUI
import AppKit

/// Tokens consumed by every Pluck SwiftUI view. Sourced from `DESIGN.md`
/// (generated via `npx getdesign@latest add apple`). Flat namespaces so call
/// sites stay terse: `Palette.accent`, `Typography.body()`, `Motion.easeOut`.

enum Palette {
    static let background   = Color(nsColor: .pluckDynamic(light: .rgb(0xf5, 0xf5, 0xf7),
                                                           dark:  .rgb(0x00, 0x00, 0x00)))
    static let surface      = Color(nsColor: .pluckDynamic(light: .white,
                                                           dark:  .rgb(0x1d, 0x1d, 0x1f)))
    static let surfaceHover = Color(nsColor: .pluckDynamic(light: .rgb(0x00, 0x00, 0x00, alpha: 0.04),
                                                           dark:  .rgb(0xff, 0xff, 0xff, alpha: 0.06)))
    static let separator    = Color(nsColor: .pluckDynamic(light: .rgb(0x00, 0x00, 0x00, alpha: 0.08),
                                                           dark:  .rgb(0xff, 0xff, 0xff, alpha: 0.10)))
    static let textPrimary  = Color(nsColor: .pluckDynamic(light: .rgb(0x1d, 0x1d, 0x1f),
                                                           dark:  .rgb(0xf5, 0xf5, 0xf7)))
    static let textSecondary = Color(nsColor: .pluckDynamic(light: .rgb(0x00, 0x00, 0x00, alpha: 0.80),
                                                            dark:  .rgb(0xff, 0xff, 0xff, alpha: 0.72)))
    static let textTertiary = Color(nsColor: .pluckDynamic(light: .rgb(0x00, 0x00, 0x00, alpha: 0.48),
                                                           dark:  .rgb(0xff, 0xff, 0xff, alpha: 0.48)))
    static let accent       = Color(nsColor: .pluckDynamic(light: .rgb(0x00, 0x71, 0xe3),
                                                           dark:  .rgb(0x29, 0x97, 0xff)))
    /// Used as-is for focus rings — DESIGN.md calls out `#0071e3` for focus
    /// regardless of appearance.
    static let focusRing    = Color(red: 0x00/255.0, green: 0x71/255.0, blue: 0xe3/255.0)
    static let onAccent     = Color.white
}

enum Metrics {
    static let sidebarWidth: CGFloat = 180
    static let contentPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 20
    static let rowSpacing: CGFloat = 10
    static let cardRadius: CGFloat = 10
    static let chipRadius: CGFloat = 8
    static let pillRadius: CGFloat = 980
    static let sidebarRowHeight: CGFloat = 30
    static let contentRowMinHeight: CGFloat = 44
    static let windowWidth: CGFloat = 700
    static let windowHeight: CGFloat = 500
}

enum Typography {
    /// Large titles — SF Display range. SwiftUI's system font picks the
    /// Display optical variant automatically at ≥20 pt.
    static func title() -> Font {
        .system(size: 28, weight: .semibold)
    }
    static func hero() -> Font {
        .system(size: 40, weight: .semibold)
    }
    static func subtitle() -> Font {
        .system(size: 17, weight: .regular)
    }
    static func sectionHeader() -> Font {
        .system(size: 11, weight: .semibold)
    }
    static func bodyEmphasized() -> Font {
        .system(size: 13, weight: .semibold)
    }
    static func body() -> Font {
        .system(size: 13, weight: .regular)
    }
    static func caption() -> Font {
        .system(size: 12, weight: .regular)
    }
    static func mono() -> Font {
        .system(size: 12, weight: .regular, design: .monospaced)
    }
}

/// Recommended tracking values straight from DESIGN.md (scaled to pt).
enum Tracking {
    static let hero: CGFloat = -0.20
    static let title: CGFloat = 0.20
    static let body: CGFloat = -0.08
    static let caption: CGFloat = -0.05
}

enum Motion {
    // Strong ease-out (emil recommends over built-in CSS eases).
    static let easeOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.18)
    static let fast    = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.12)
    static let slower  = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
}

// MARK: - Press feedback

/// ButtonStyle that scales to 0.97 on press (120 ms ease-out) unless the
/// user has Reduce Motion enabled. Applies to any Button via `.buttonStyle(.pluckPress)`.
struct PluckPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale(for: configuration.isPressed))
            .animation(Motion.fast, value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private func scale(for pressed: Bool) -> CGFloat {
        guard pressed, !reduceMotion else { return 1 }
        return 0.97
    }
}

extension ButtonStyle where Self == PluckPressButtonStyle {
    static var pluckPress: PluckPressButtonStyle { PluckPressButtonStyle() }
}

// MARK: - NSColor helpers

extension NSColor {
    /// Dynamic NSColor that flips between `light` and `dark` per appearance.
    /// Resolved by AppKit at draw time, so SwiftUI views observe the change
    /// without a reload when the user flips the system appearance.
    static func pluckDynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua]) ?? .aqua
            return match == .darkAqua ? dark : light
        }
    }

    /// 0–255 RGB convenience.
    static func rgb(_ r: Int, _ g: Int, _ b: Int, alpha: CGFloat = 1) -> NSColor {
        NSColor(srgbRed: CGFloat(r) / 255.0,
                green:   CGFloat(g) / 255.0,
                blue:    CGFloat(b) / 255.0,
                alpha:   alpha)
    }
}
