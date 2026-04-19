import CoreGraphics

protocol KeystrokeSender: AnyObject, Sendable {
    func sendCopy()
}

/// Synthesizes Cmd+C by posting two CGEvents to the session event tap.
/// Key code for `c` is 8 on the ANSI layout.
final class SystemKeystrokeSender: KeystrokeSender, @unchecked Sendable {
    private let keyCodeC: CGKeyCode = 8

    func sendCopy() {
        guard
            let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeC, keyDown: true),
            let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeC, keyDown: false)
        else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cgSessionEventTap)
        up.post(tap: .cgSessionEventTap)
    }
}
