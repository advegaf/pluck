import AppKit
import Testing
@testable import Pluck

@MainActor
struct HUDPresenterTests {
    /// The panel takes each label's size: a longer count makes a wider pill,
    /// and a shorter one a narrower pill again.
    @Test func pillsOfDifferentLengthsResizeThePanel() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let hud = HUDPresenter()
        hud.show(near: .zero, characterCount: 1)
        hud.panel?.displayIfNeeded()
        let short = try #require(hud.panel).frame.width
        hud.show(near: .zero, characterCount: 1_234_567)
        hud.panel?.displayIfNeeded()
        let long = try #require(hud.panel).frame.width
        #expect(long > short)
        hud.show(near: .zero, characterCount: 1)
        hud.panel?.displayIfNeeded()
        #expect(try #require(hud.panel).frame.width == short)
    }
}
