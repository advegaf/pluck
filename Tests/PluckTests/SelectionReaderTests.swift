import Testing
import Foundation
import CoreGraphics
@testable import Pluck

/// Thread-safe in-memory pasteboard stand-in.
final class FakePasteboard: Pasteboard, @unchecked Sendable {
    private let lock = NSLock()
    private var _changeCount: Int = 0
    private var _string: String?

    var changeCountBumpsOnCopy = false

    var changeCount: Int { lock.withLock { _changeCount } }

    func readString() -> String? { lock.withLock { _string } }

    func write(_ string: String) {
        lock.withLock {
            _string = string
            _changeCount += 1
        }
    }

    func snapshot() -> PasteboardSnapshot { .empty }
    func restore(_ snapshot: PasteboardSnapshot) {
        lock.withLock {
            _string = nil
            _changeCount += 1
        }
    }

    func simulateCopyProducing(_ text: String?) {
        lock.withLock {
            _string = text
            _changeCount += 1
        }
    }
}

final class FakeAXSource: AXSelectionSource, @unchecked Sendable {
    var result: AXSelectionRead?
    func readSelection(at screenPoint: CGPoint) -> AXSelectionRead? { result }
}

final class FakeKeystrokeSender: KeystrokeSender, @unchecked Sendable {
    var onSend: (@Sendable () -> Void)?
    var sendCount = 0
    func sendCopy() {
        sendCount += 1
        onSend?()
    }
}

final class FakeFrontmost: FrontmostAppProvider, @unchecked Sendable {
    var value: String?
    func frontmostBundleID() -> String? { value }
}

private func makeBlocklist(_ entries: [String]) -> Blocklist {
    let defaults = UserDefaults(suiteName: "pluck.test.\(UUID().uuidString)")!
    defaults.set(entries, forKey: "pluck.blocklist")
    return Blocklist(defaults: defaults, key: "pluck.blocklist")
}

struct SelectionReaderTests {
    @Test func axHitPopulatesClipboardAndReturnsAXSource() async {
        let ax = FakeAXSource()
        ax.result = AXSelectionRead(text: "hello", bundleID: "com.apple.Safari")
        let pb = FakePasteboard()
        let keys = FakeKeystrokeSender()
        let reader = SelectionReader(
            ax: ax, pasteboard: pb, keys: keys,
            frontmost: FakeFrontmost(),
            blocklist: makeBlocklist([])
        )
        let result = await reader.read(at: .zero)
        #expect(result?.text == "hello")
        #expect(result?.source == .ax)
        #expect(pb.readString() == "hello")
        #expect(keys.sendCount == 0)
    }

    @Test func axHitFromBlockedAppReturnsNil() async {
        let ax = FakeAXSource()
        ax.result = AXSelectionRead(text: "hello", bundleID: "com.figma.Desktop")
        let pb = FakePasteboard()
        let keys = FakeKeystrokeSender()
        let reader = SelectionReader(
            ax: ax, pasteboard: pb, keys: keys,
            frontmost: FakeFrontmost(),
            blocklist: makeBlocklist(["com.figma.Desktop"])
        )
        let result = await reader.read(at: .zero)
        #expect(result == nil)
        #expect(keys.sendCount == 0)
    }

    @Test func axEmptyTriggersFallbackWhichSucceeds() async {
        let ax = FakeAXSource()
        ax.result = AXSelectionRead(text: "", bundleID: "com.microsoft.VSCode")
        let pb = FakePasteboard()
        let keys = FakeKeystrokeSender()
        keys.onSend = { [pb] in pb.simulateCopyProducing("from-cmd-c") }
        let reader = SelectionReader(
            ax: ax, pasteboard: pb, keys: keys,
            frontmost: FakeFrontmost(),
            blocklist: makeBlocklist([])
        )
        let result = await reader.read(at: .zero)
        #expect(result?.text == "from-cmd-c")
        #expect(result?.source == .fallback)
        #expect(keys.sendCount == 1)
    }

    @Test func axNilFallsBackViaFrontmostAndSucceeds() async {
        let ax = FakeAXSource()
        ax.result = nil
        let pb = FakePasteboard()
        let keys = FakeKeystrokeSender()
        keys.onSend = { [pb] in pb.simulateCopyProducing("fallback") }
        let frontmost = FakeFrontmost(); frontmost.value = "com.apple.Terminal"
        let reader = SelectionReader(
            ax: ax, pasteboard: pb, keys: keys,
            frontmost: frontmost,
            blocklist: makeBlocklist([])
        )
        let result = await reader.read(at: .zero)
        #expect(result?.text == "fallback")
        #expect(result?.source == .fallback)
    }

    @Test func fallbackIsSkippedForBlockedFrontmostApp() async {
        let ax = FakeAXSource()
        ax.result = nil
        let pb = FakePasteboard()
        let keys = FakeKeystrokeSender()
        let frontmost = FakeFrontmost(); frontmost.value = "com.figma.Desktop"
        let reader = SelectionReader(
            ax: ax, pasteboard: pb, keys: keys,
            frontmost: frontmost,
            blocklist: makeBlocklist(["com.figma.Desktop"])
        )
        let result = await reader.read(at: .zero)
        #expect(result == nil)
        #expect(keys.sendCount == 0)
    }

    @Test func fallbackThatFailsReturnsNilAndKeysWereSent() async {
        let ax = FakeAXSource()
        ax.result = nil
        let pb = FakePasteboard()
        let keys = FakeKeystrokeSender()
        // No onSend hook — clipboard never changes.
        let reader = SelectionReader(
            ax: ax, pasteboard: pb, keys: keys,
            frontmost: FakeFrontmost(),
            blocklist: makeBlocklist([])
        )
        reader.fallbackTimeout = 0.05
        reader.fallbackPollStep = 0.005
        let result = await reader.read(at: .zero)
        #expect(result == nil)
        #expect(keys.sendCount == 1)
    }
}
