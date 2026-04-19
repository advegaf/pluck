import Testing
import CoreGraphics
@testable import Pluck

struct GestureStateMachineTests {
    @Test func mouseDownSchedulesHoldTimer() {
        var sm = GestureStateMachine()
        let action = sm.onMouseDown(at: CGPoint(x: 10, y: 20))
        #expect(action == .scheduleHoldTimer(delay: 0.15))
        #expect(sm.pressPoint == CGPoint(x: 10, y: 20))
    }

    @Test func customDelayIsHonored() {
        var sm = GestureStateMachine()
        sm.holdDelay = 0.25
        let action = sm.onMouseDown(at: .zero)
        #expect(action == .scheduleHoldTimer(delay: 0.25))
    }

    @Test func mouseUpBeforeTimerCancels() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 1, y: 2))
        let up = sm.onMouseUp()
        #expect(up == .cancelHoldTimer)
        #expect(sm.pressPoint == nil)
    }

    @Test func dragBeyondSlopCancelsTheTimer() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 100, y: 100))
        let drag = sm.onMouseDragged(to: CGPoint(x: 120, y: 100))
        #expect(drag == .cancelHoldTimer)
        #expect(sm.pressPoint == nil)
    }

    @Test func dragWithinSlopKeepsTheTimerArmed() {
        var sm = GestureStateMachine()
        sm.dragSlop = 4.0
        _ = sm.onMouseDown(at: CGPoint(x: 100, y: 100))
        let jitter1 = sm.onMouseDragged(to: CGPoint(x: 101, y: 100))
        let jitter2 = sm.onMouseDragged(to: CGPoint(x: 100, y: 103))
        let jitter3 = sm.onMouseDragged(to: CGPoint(x: 103, y: 103)) // dist ≈ 4.24 > 4 → cancels
        #expect(jitter1 == nil)
        #expect(jitter2 == nil)
        #expect(jitter3 == .cancelHoldTimer)
    }

    @Test func dragAtExactlySlopKeepsTimerArmed() {
        var sm = GestureStateMachine()
        sm.dragSlop = 4.0
        _ = sm.onMouseDown(at: CGPoint(x: 0, y: 0))
        let onBoundary = sm.onMouseDragged(to: CGPoint(x: 4, y: 0))
        #expect(onBoundary == nil)
        #expect(sm.pressPoint == CGPoint(x: 0, y: 0))
    }

    @Test func resetClearsPendingPress() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 5, y: 5))
        sm.reset()
        #expect(sm.pressPoint == nil)
        #expect(sm.onHoldTimerFired() == nil)
    }

    @Test func resetPreservesHoldDelay() {
        var sm = GestureStateMachine()
        sm.holdDelay = 0.30
        _ = sm.onMouseDown(at: .zero)
        sm.reset()
        let action = sm.onMouseDown(at: .zero)
        #expect(action == .scheduleHoldTimer(delay: 0.30))
    }

    @Test func timerFireAfterCancelIsNoOp() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 5, y: 6))
        _ = sm.onMouseUp()
        let fire = sm.onHoldTimerFired()
        #expect(fire == nil)
    }

    @Test func timerFireWhileStillPressedEmitsCopy() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 5, y: 6))
        let fire = sm.onHoldTimerFired()
        #expect(fire == .fireCopy(at: CGPoint(x: 5, y: 6)))
        #expect(sm.pressPoint == CGPoint(x: 5, y: 6))
    }

    @Test func mouseUpAfterFireStillClearsState() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 5, y: 6))
        _ = sm.onHoldTimerFired()
        let up = sm.onMouseUp()
        #expect(up == .cancelHoldTimer)
        #expect(sm.pressPoint == nil)
    }

    @Test func mouseUpFromIdleIsNoOp() {
        var sm = GestureStateMachine()
        let up = sm.onMouseUp()
        #expect(up == nil)
    }

    @Test func dragFromIdleIsNoOp() {
        var sm = GestureStateMachine()
        let drag = sm.onMouseDragged(to: CGPoint(x: 1_000, y: 1_000))
        #expect(drag == nil)
    }
}
