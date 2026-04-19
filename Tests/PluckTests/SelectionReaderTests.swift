import Testing
import Foundation
import CoreGraphics
@testable import Pluck

final class FakePasteboard: Pasteboard, @unchecked Sendable {
    private let lock = NSLock()
    private var _string: String?
    func readString() -> String? { lock.withLock { _string } }
    func write(_ string: String) { lock.withLock { _string = string } }
}

final class FakeAXSource: AXSelectionSource, @unchecked Sendable {
    var result: AXHit = .miss
    func readSelection(at screenPoint: CGPoint) -> AXHit { result }
}

private func makeBlocklist(_ entries: [String]) -> Blocklist {
    let defaults = UserDefaults(suiteName: "pluck.test.\(UUID().uuidString)")!
    defaults.set(entries, forKey: "pluck.blocklist")
    return Blocklist(defaults: defaults, key: "pluck.blocklist")
}

struct SelectionReaderTests {
    @Test func axSelectionWritesClipboardAndReturnsText() async {
        let ax = FakeAXSource()
        ax.result = .selection("hello", bundleID: "com.apple.Safari")
        let pb = FakePasteboard()
        let reader = SelectionReader(ax: ax, pasteboard: pb,
                                     blocklist: makeBlocklist([]))
        let outcome = await reader.read(at: .zero)
        #expect(outcome?.text == "hello")
        #expect(pb.readString() == "hello")
    }

    @Test func axSelectionFromBlockedAppReturnsNilAndDoesNotWrite() async {
        let ax = FakeAXSource()
        ax.result = .selection("hello", bundleID: "com.figma.Desktop")
        let pb = FakePasteboard()
        let reader = SelectionReader(ax: ax, pasteboard: pb,
                                     blocklist: makeBlocklist(["com.figma.Desktop"]))
        let outcome = await reader.read(at: .zero)
        #expect(outcome == nil)
        #expect(pb.readString() == nil)
    }

    /// Regression: AX-reported "no selection" must be a silent no-op. The
    /// previous bug synthesized Cmd+C here, which made apps NSBeep.
    @Test func axNoSelectionIsSilentNoOp() async {
        let ax = FakeAXSource()
        ax.result = .noSelection(bundleID: "com.apple.Safari")
        let pb = FakePasteboard()
        let reader = SelectionReader(ax: ax, pasteboard: pb,
                                     blocklist: makeBlocklist([]))
        let outcome = await reader.read(at: .zero)
        #expect(outcome == nil)
        #expect(pb.readString() == nil)
    }

    @Test func axMissIsSilentNoOp() async {
        let ax = FakeAXSource()
        ax.result = .miss
        let pb = FakePasteboard()
        let reader = SelectionReader(ax: ax, pasteboard: pb,
                                     blocklist: makeBlocklist([]))
        let outcome = await reader.read(at: .zero)
        #expect(outcome == nil)
        #expect(pb.readString() == nil)
    }
}
