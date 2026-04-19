import AppKit
import CoreGraphics

/// Installs a listen-only CGEventTap for left mouse events and drives a
/// `GestureStateMachine`. On a ≥`holdDelayMs` dwell it fires `onHoldThreshold`
/// with the mouse-down screen point. Events are never modified.
@MainActor
final class GestureEngine {
    enum StartError: Error {
        case tapCreationFailed
    }

    private var machine = GestureStateMachine()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var holdWork: DispatchWorkItem?

    var onHoldThreshold: ((CGPoint) -> Void)?

    private(set) var isRunning = false
    var isPaused = false

    var holdDelayMs: Int {
        get { Int(machine.holdDelay * 1000) }
        set { machine.holdDelay = Double(max(50, newValue)) / 1000.0 }
    }

    func start() throws {
        guard !isRunning else { return }

        let mask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: engineTapCallback,
            userInfo: userInfo
        ) else {
            throw StartError.tapCreationFailed
        }
        self.tap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        holdWork?.cancel()
        holdWork = nil
        tap = nil
        runLoopSource = nil
        isRunning = false
    }

    fileprivate func handle(type: CGEventType, location: CGPoint) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard !isPaused else { return }

        switch type {
        case .leftMouseDown:
            apply(machine.onMouseDown(at: location))
        case .leftMouseUp:
            if let action = machine.onMouseUp() { apply(action) }
        case .leftMouseDragged:
            if let action = machine.onMouseDragged() { apply(action) }
        default:
            break
        }
    }

    private func apply(_ action: GestureStateMachine.Action) {
        switch action {
        case .scheduleHoldTimer(let delay):
            holdWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                MainActor.assumeIsolated {
                    self?.fireHoldTimer()
                }
            }
            holdWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        case .cancelHoldTimer:
            holdWork?.cancel()
            holdWork = nil
        case .fireCopy(let point):
            onHoldThreshold?(point)
        }
    }

    private func fireHoldTimer() {
        holdWork = nil
        if let action = machine.onHoldTimerFired() { apply(action) }
    }
}

private let engineTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    if let userInfo {
        let engine = Unmanaged<GestureEngine>.fromOpaque(userInfo).takeUnretainedValue()
        let location = event.location
        MainActor.assumeIsolated {
            engine.handle(type: type, location: location)
        }
    }
    return Unmanaged.passUnretained(event)
}
