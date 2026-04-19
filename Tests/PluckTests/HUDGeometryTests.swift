import Testing
import CoreGraphics
@testable import Pluck

struct HUDGeometryTests {
    private let pill = CGSize(width: 120, height: 32)
    // AppKit main screen: 0,0 = bottom-left. Frame 1440x900.
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test func normalCaseBelowRightOfCursor() {
        let origin = HUDGeometry.panelOrigin(
            anchor: CGPoint(x: 300, y: 500),
            pillSize: pill,
            screenFrame: screen
        )
        #expect(origin.x == 300 + HUDGeometry.offset.width)
        #expect(origin.y == 500 - pill.height - HUDGeometry.offset.height)
    }

    @Test func clampsToRightEdge() {
        let origin = HUDGeometry.panelOrigin(
            anchor: CGPoint(x: 1435, y: 500),
            pillSize: pill,
            screenFrame: screen
        )
        #expect(origin.x == screen.maxX - pill.width - HUDGeometry.screenInset)
    }

    @Test func clampsToBottomEdge() {
        // anchor near y=0 (bottom of screen) → computed proposedY is negative.
        let origin = HUDGeometry.panelOrigin(
            anchor: CGPoint(x: 300, y: 10),
            pillSize: pill,
            screenFrame: screen
        )
        #expect(origin.y == screen.minY + HUDGeometry.screenInset)
    }

    @Test func clampsToTopEdge() {
        let origin = HUDGeometry.panelOrigin(
            anchor: CGPoint(x: 300, y: 5_000),
            pillSize: pill,
            screenFrame: screen
        )
        #expect(origin.y <= screen.maxY - pill.height - HUDGeometry.screenInset)
    }

    @Test func clampsToLeftEdge() {
        let origin = HUDGeometry.panelOrigin(
            anchor: CGPoint(x: -100, y: 500),
            pillSize: pill,
            screenFrame: screen
        )
        #expect(origin.x == screen.minX + HUDGeometry.screenInset)
    }

    @Test func handlesSecondaryScreenWithNonZeroOrigin() {
        let secondary = CGRect(x: 1440, y: 200, width: 1024, height: 768)
        let origin = HUDGeometry.panelOrigin(
            anchor: CGPoint(x: 1500, y: 800),
            pillSize: pill,
            screenFrame: secondary
        )
        #expect(origin.x >= secondary.minX + HUDGeometry.screenInset)
        #expect(origin.x <= secondary.maxX - pill.width - HUDGeometry.screenInset)
        #expect(origin.y >= secondary.minY + HUDGeometry.screenInset)
        #expect(origin.y <= secondary.maxY - pill.height - HUDGeometry.screenInset)
    }
}
