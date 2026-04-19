import AppKit

struct SelectionOutcome: Equatable, Sendable {
    enum Source: Equatable, Sendable { case ax, fallback }
    var text: String
    var source: Source
}

protocol FrontmostAppProvider: Sendable {
    func frontmostBundleID() -> String?
}

final class SystemFrontmostAppProvider: FrontmostAppProvider, @unchecked Sendable {
    func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}

/// Returns the selected text at a screen point, preferring the AX API and
/// falling back to a synthesized Cmd+C with clipboard restore. Honors the
/// blocklist before either path.
final class SelectionReader: @unchecked Sendable {
    private let ax: AXSelectionSource
    private let pasteboard: Pasteboard
    private let keys: KeystrokeSender
    private let frontmost: FrontmostAppProvider
    private let blocklist: Blocklist

    /// How long to poll the pasteboard for a changeCount bump after Cmd+C.
    var fallbackTimeout: TimeInterval = 0.12
    var fallbackPollStep: TimeInterval = 0.005

    init(
        ax: AXSelectionSource = SystemAXSelectionSource(),
        pasteboard: Pasteboard = SystemPasteboard(),
        keys: KeystrokeSender = SystemKeystrokeSender(),
        frontmost: FrontmostAppProvider = SystemFrontmostAppProvider(),
        blocklist: Blocklist
    ) {
        self.ax = ax
        self.pasteboard = pasteboard
        self.keys = keys
        self.frontmost = frontmost
        self.blocklist = blocklist
    }

    func read(at screenPoint: CGPoint) async -> SelectionOutcome? {
        let axRead = ax.readSelection(at: screenPoint)
        let bundleID = axRead?.bundleID ?? frontmost.frontmostBundleID()
        if let bundleID, blocklist.contains(bundleID) {
            return nil
        }

        if let axRead, !axRead.text.isEmpty {
            pasteboard.write(axRead.text)
            return SelectionOutcome(text: axRead.text, source: .ax)
        }

        return await fallbackCopy()
    }

    private func fallbackCopy() async -> SelectionOutcome? {
        let snapshot = pasteboard.snapshot()
        let beforeChange = pasteboard.changeCount
        keys.sendCopy()

        let deadline = Date().addingTimeInterval(fallbackTimeout)
        while Date() < deadline {
            if pasteboard.changeCount != beforeChange { break }
            let step = UInt64(fallbackPollStep * 1_000_000_000)
            try? await Task.sleep(nanoseconds: step)
        }

        if pasteboard.changeCount != beforeChange,
           let text = pasteboard.readString(), !text.isEmpty {
            return SelectionOutcome(text: text, source: .fallback)
        }

        pasteboard.restore(snapshot)
        return nil
    }
}
