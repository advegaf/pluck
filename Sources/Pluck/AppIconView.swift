import SwiftUI
import AppKit

/// Renders the app's own icon at the requested point size.
///
/// Pulls from `NSApp.applicationIconImage`, which macOS seeds from
/// `Contents/Resources/AppIcon.icns` via `CFBundleIconFile`. Single
/// source of truth — no duplicate PNG needs shipping inside the bundle.
/// NSImage picks the best-matching representation from the ICNS (16,
/// 32, 64, 128, 256, 512, 1024 @1x and @2x) for the drawn size, so a
/// 32pt render on a retina display draws the 64px rep, and a 64pt
/// render draws the 128px rep — always pixel-perfect.
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }
}
