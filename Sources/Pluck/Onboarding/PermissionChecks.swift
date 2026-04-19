import AppKit
import ApplicationServices

enum Permission: String, Hashable, Sendable {
    case accessibility
    case inputMonitoring
}

enum PermissionChecks {
    // `kAXTrustedCheckOptionPrompt` is declared as a mutable C global, which
    // Swift 6 strict-concurrency flags. The value is a well-known constant
    // CFString literal; inline it to sidestep the diagnostic.
    private static let axPromptKey = "AXTrustedCheckOptionPrompt"

    static func accessibilityTrusted(prompt: Bool = false) -> Bool {
        let options: CFDictionary = [axPromptKey: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// `IOHIDCheckAccess(.listenEvent)` is the listen-only variant — matches
    /// our `.listenOnly` CGEventTap. Requires macOS 10.15+.
    static func inputMonitoringGranted() -> Bool {
        let status = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
        return status == kIOHIDAccessTypeGranted
    }

    static func status(for permission: Permission) -> Bool {
        switch permission {
        case .accessibility: return accessibilityTrusted()
        case .inputMonitoring: return inputMonitoringGranted()
        }
    }

    static func openSettings(for permission: Permission) {
        let url: URL? = switch permission {
        case .accessibility:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .inputMonitoring:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        }
        if let url { NSWorkspace.shared.open(url) }
    }
}
