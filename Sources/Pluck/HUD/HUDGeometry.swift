import CoreGraphics

/// Positions the HUD pill below-right of the cursor, clamped into the given
/// screen frame with an inset. Pure function so it's trivial to unit-test.
enum HUDGeometry {
    static let offset = CGSize(width: 18, height: 18)
    static let screenInset: CGFloat = 8

    static func panelOrigin(
        anchor: CGPoint,
        pillSize: CGSize,
        screenFrame: CGRect
    ) -> CGPoint {
        let proposedX = anchor.x + offset.width
        // AppKit origin is bottom-left; we want the panel BELOW the cursor,
        // which means a smaller y (i.e. anchor.y - pillSize.height - offset).
        let proposedY = anchor.y - pillSize.height - offset.height

        let minX = screenFrame.minX + screenInset
        let maxX = screenFrame.maxX - pillSize.width - screenInset
        let minY = screenFrame.minY + screenInset
        let maxY = screenFrame.maxY - pillSize.height - screenInset

        let clampedX = min(max(proposedX, minX), max(minX, maxX))
        let clampedY = min(max(proposedY, minY), max(minY, maxY))
        return CGPoint(x: clampedX, y: clampedY)
    }
}
