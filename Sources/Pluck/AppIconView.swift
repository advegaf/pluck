import SwiftUI
import AppKit

/// Renders the app's own icon at the requested point size.
///
/// Loads `AppIcon.icns` directly from the bundle rather than going
/// through `NSApp.applicationIconImage`. On macOS 26 Tahoe, the latter
/// can return an image with the OS's Dock-squircle treatment pre-applied
/// — which looks like extra padding inside the view frame. Loading the
/// ICNS file gives us the raw multi-resolution art as the user exported
/// it, edge-to-edge within the frame.
///
/// NSImage picks the closest-size representation from the ICNS (16, 32,
/// 64, 128, 256, 512, 1024 px) for the drawn size, so a 32pt frame on
/// retina draws the 64px rep, a 64pt frame draws the 128px rep — always
/// pixel-perfect.
struct AppIconView: View {
    let size: CGFloat

    private static let icon: NSImage = {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSApp.applicationIconImage
    }()

    var body: some View {
        Image(nsImage: Self.icon)
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }
}
