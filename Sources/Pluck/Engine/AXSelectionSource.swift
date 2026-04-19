import AppKit
import ApplicationServices

/// Outcome of probing AX for selected text at a screen point. Any AX error
/// collapses to `.noSelection` — the alternative (synthesized Cmd+C) made
/// every click in a non-text element beep. AX-only behavior: if AX doesn't
/// report a selection, Pluck silently does nothing.
enum AXHit: Sendable {
    case selection(String, bundleID: String?)
    case noSelection(bundleID: String?)
    case miss

    var bundleID: String? {
        switch self {
        case .selection(_, let b), .noSelection(let b): return b
        case .miss: return nil
        }
    }
}

protocol AXSelectionSource: AnyObject, Sendable {
    func readSelection(at screenPoint: CGPoint) -> AXHit
}

final class SystemAXSelectionSource: AXSelectionSource, @unchecked Sendable {
    /// Reads the current selection by asking the system-wide FOCUSED UI
    /// element for its `kAXSelectedTextAttribute`. This is the element
    /// that owns the current keyboard focus/selection — a text field,
    /// NSTextView, or Safari's AXWebArea. Hit-testing at the cursor
    /// point (the old implementation) returned the leaf element, which
    /// in Safari and most web browsers is an AXStaticText node that
    /// does NOT itself expose selected text — the web area's parent does.
    /// As a fallback we still try hit-testing, in case the focus path
    /// doesn't resolve in some app.
    func readSelection(at screenPoint: CGPoint) -> AXHit {
        let systemWide = AXUIElementCreateSystemWide()

        if let hit = readFromFocused(systemWide: systemWide) {
            return hit
        }
        return readFromHitTest(systemWide: systemWide, at: screenPoint)
    }

    private func readFromFocused(systemWide: AXUIElement) -> AXHit? {
        var focused: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focused
        )
        guard focusResult == .success, let focused else { return nil }
        let element = focused as! AXUIElement
        let bundleID = Self.bundleID(of: element)

        let text = Self.readSelectedText(from: element)
        if let text, !text.isEmpty {
            return .selection(text, bundleID: bundleID)
        }
        return .noSelection(bundleID: bundleID)
    }

    private func readFromHitTest(systemWide: AXUIElement, at screenPoint: CGPoint) -> AXHit {
        var element: AXUIElement?
        let hit = AXUIElementCopyElementAtPosition(
            systemWide,
            Float(screenPoint.x),
            Float(screenPoint.y),
            &element
        )
        guard hit == .success, let element else { return .miss }

        let bundleID = Self.bundleID(of: element)

        // Walk up the AX hierarchy looking for a non-empty selected text.
        // The leaf element is usually a static-text node; the selection
        // attribute lives on an ancestor (text view, web area).
        var current: AXUIElement? = element
        var depth = 0
        while let node = current, depth < 8 {
            if let text = Self.readSelectedText(from: node), !text.isEmpty {
                return .selection(text, bundleID: bundleID)
            }
            current = Self.parent(of: node)
            depth += 1
        }
        return .noSelection(bundleID: bundleID)
    }

    private static func readSelectedText(from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &value
        )
        guard result == .success, let value else { return nil }
        return value as? String
    }

    private static func parent(of element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXParentAttribute as CFString,
            &value
        )
        guard result == .success, let value else { return nil }
        return (value as! AXUIElement)
    }

    private static func bundleID(of element: AXUIElement) -> String? {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }
}
