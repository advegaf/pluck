import Foundation
import CoreGraphics

/// Pure state machine for the hold-to-copy gesture. No timers, no OS calls.
/// The engine feeds it events and consumes the returned `Action`s.
struct GestureStateMachine: Sendable {
    enum Action: Equatable, Sendable {
        case scheduleHoldTimer(delay: TimeInterval)
        case cancelHoldTimer
        case fireCopy(at: CGPoint)
    }

    var holdDelay: TimeInterval = 0.15

    /// Drag events within this distance of the press point do NOT cancel
    /// the hold timer. Hand tremor and trackpad jitter commonly emit 1–3 pt
    /// drags during a stationary hold.
    var dragSlop: CGFloat = 4.0

    private(set) var pressPoint: CGPoint?

    mutating func onMouseDown(at point: CGPoint) -> Action {
        pressPoint = point
        return .scheduleHoldTimer(delay: holdDelay)
    }

    mutating func onMouseUp() -> Action? {
        guard pressPoint != nil else { return nil }
        pressPoint = nil
        return .cancelHoldTimer
    }

    mutating func onMouseDragged(to point: CGPoint) -> Action? {
        guard let anchor = pressPoint else { return nil }
        let dx = point.x - anchor.x
        let dy = point.y - anchor.y
        if dx * dx + dy * dy <= dragSlop * dragSlop {
            return nil
        }
        pressPoint = nil
        return .cancelHoldTimer
    }

    mutating func onHoldTimerFired() -> Action? {
        guard let point = pressPoint else { return nil }
        return .fireCopy(at: point)
    }

    /// Clear all in-flight press state. Call when the event tap is
    /// disabled and re-enabled to avoid leaking a stale press.
    mutating func reset() {
        pressPoint = nil
    }
}
