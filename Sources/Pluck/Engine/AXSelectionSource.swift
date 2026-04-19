import AppKit
import ApplicationServices

struct AXSelectionRead: Equatable, Sendable {
    var text: String
    var bundleID: String?
}

protocol AXSelectionSource: AnyObject, Sendable {
    /// Returns the selected text under the given screen point plus the bundle
    /// ID of the owning app, or nil if no selected text is available via AX.
    func readSelection(at screenPoint: CGPoint) -> AXSelectionRead?
}

final class SystemAXSelectionSource: AXSelectionSource, @unchecked Sendable {
    func readSelection(at screenPoint: CGPoint) -> AXSelectionRead? {
        let systemWide = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        let hitResult = AXUIElementCopyElementAtPosition(
            systemWide,
            Float(screenPoint.x),
            Float(screenPoint.y),
            &element
        )
        guard hitResult == .success, let element else { return nil }

        var selectedValue: CFTypeRef?
        let selResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        )
        let text = (selResult == .success) ? (selectedValue as? String) : nil

        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        let bundleID = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier

        if let text, !text.isEmpty {
            return AXSelectionRead(text: text, bundleID: bundleID)
        }
        if let bundleID {
            return AXSelectionRead(text: "", bundleID: bundleID)
        }
        return nil
    }
}
