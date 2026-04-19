import CoreGraphics

/// The HUD lives at bottom-center of the screen containing the cursor,
/// matching macOS system HUDs (volume, AirPods, focus). Pure function so
/// it's trivial to unit-test.
enum HUDGeometry {
    /// Distance from the bottom of the visible frame to the pill.
    static let bottomOffset: CGFloat = 120

    /// Origin (bottom-left in AppKit coordinates) for a pill of `pillSize`
    /// placed horizontally centered in the given screen frame, offset
    /// `bottomOffset` points up from the bottom edge.
    static func panelOrigin(pillSize: CGSize, screenFrame: CGRect) -> CGPoint {
        let x = screenFrame.midX - pillSize.width / 2
        let y = screenFrame.minY + bottomOffset
        return CGPoint(x: x, y: y)
    }
}
