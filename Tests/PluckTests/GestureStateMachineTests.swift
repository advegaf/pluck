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

    @Test func dragCancelsTheTimer() {
        var sm = GestureStateMachine()
        _ = sm.onMouseDown(at: CGPoint(x: 1, y: 2))
        let drag = sm.onMouseDragged()
        #expect(drag == .cancelHoldTimer)
        #expect(sm.pressPoint == nil)
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
        let drag = sm.onMouseDragged()
        #expect(drag == nil)
    }
}
