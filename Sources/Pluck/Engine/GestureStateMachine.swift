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

    mutating func onMouseDragged() -> Action? {
        guard pressPoint != nil else { return nil }
        pressPoint = nil
        return .cancelHoldTimer
    }

    mutating func onHoldTimerFired() -> Action? {
        guard let point = pressPoint else { return nil }
        return .fireCopy(at: point)
    }
}
