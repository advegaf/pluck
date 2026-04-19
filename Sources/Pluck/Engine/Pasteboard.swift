import AppKit

/// Minimal clipboard abstraction. AX-only selection reading means we no
/// longer need snapshot/restore (those existed to recover from a
/// synthesized Cmd+C that captured nothing).
protocol Pasteboard: AnyObject, Sendable {
    func readString() -> String?
    func write(_ string: String)
}

final class SystemPasteboard: Pasteboard, @unchecked Sendable {
    private let pb = NSPasteboard.general

    func readString() -> String? {
        pb.string(forType: .string)
    }

    func write(_ string: String) {
        pb.clearContents()
        pb.setString(string, forType: .string)
    }
}
