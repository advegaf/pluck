import AppKit
import SwiftUI

@MainActor
@Observable
final class AppShell {
    let blocklist: Blocklist
    let engine: GestureEngine
    let selectionReader: SelectionReader
    let hud: HUDPresenter
    let onboardingState: OnboardingState
    private var onboardingWindow: NSWindow?

    var isPaused: Bool {
        get { engine.isPaused }
        set { engine.isPaused = newValue }
    }

    init() {
        let blocklist = Blocklist()
        self.blocklist = blocklist
        self.engine = GestureEngine()
        self.selectionReader = SelectionReader(blocklist: blocklist)
        self.hud = HUDPresenter()
        self.onboardingState = OnboardingState()

        let storedDelay = UserDefaults.standard.integer(forKey: "pluck.holdDelayMs")
        engine.holdDelayMs = storedDelay == 0 ? 150 : storedDelay

        engine.onHoldThreshold = { [weak self] point in
            self?.handleHold(at: point)
        }
    }

    func bootstrap() {
        if onboardingState.allGranted {
            startEngineIfPossible()
        } else {
            showOnboarding()
        }
    }

    func handleHold(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let currentDelay = UserDefaults.standard.integer(forKey: "pluck.holdDelayMs")
            if currentDelay > 0, currentDelay != self.engine.holdDelayMs {
                self.engine.holdDelayMs = currentDelay
            }
            if let outcome = await self.selectionReader.read(at: point) {
                _ = outcome
                let hudEnabled = UserDefaults.standard.object(forKey: "pluck.hudEnabled") as? Bool ?? true
                if hudEnabled {
                    self.hud.show(near: point)
                }
            }
        }
    }

    func showOnboarding() {
        if let win = onboardingWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let view = OnboardingView(state: onboardingState) { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.onboardingState.stopPolling()
            self?.startEngineIfPossible()
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Pluck"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        onboardingWindow = window
        onboardingState.beginPolling()
    }

    func startEngineIfPossible() {
        guard PermissionChecks.accessibilityTrusted(),
              PermissionChecks.inputMonitoringGranted() else {
            showOnboarding()
            return
        }
        do {
            try engine.start()
        } catch {
            NSLog("Pluck: failed to start event tap: \(error)")
        }
    }
}
