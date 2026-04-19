import AppKit
import SwiftUI

@MainActor
@Observable
final class AppShell: NSObject, NSWindowDelegate {
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

    override init() {
        let blocklist = Blocklist()
        self.blocklist = blocklist
        self.engine = GestureEngine()
        self.selectionReader = SelectionReader(blocklist: blocklist)
        self.hud = HUDPresenter()
        self.onboardingState = OnboardingState()
        super.init()

        let storedDelay = UserDefaults.standard.integer(forKey: "pluck.holdDelayMs")
        engine.holdDelayMs = storedDelay == 0 ? 150 : storedDelay

        engine.onHoldThreshold = { [weak self] point in
            self?.handleHold(at: point)
        }
    }

    /// Persisted in UserDefaults so onboarding reappears on relaunch until
    /// the user has explicitly closed the window with both permissions
    /// granted. Decouples "permissions are satisfied" from "user has seen
    /// and confirmed the setup flow".
    var onboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: "pluck.onboardingCompleted") }
        set { UserDefaults.standard.set(newValue, forKey: "pluck.onboardingCompleted") }
    }

    func bootstrap() {
        // Additive, not exclusive: engine starts whenever permissions are
        // granted, AND onboarding opens when either permissions are missing
        // OR the user has not yet confirmed setup. This makes the common
        // quit-after-granting-Input-Monitoring → relaunch flow work: the
        // engine is already live while the user clicks "Start using Pluck"
        // one last time to close the loop.
        if onboardingState.allGranted {
            startEngineIfPossible()
        }
        if !onboardingState.allGranted || !onboardingCompleted {
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
            if await self.selectionReader.read(at: point) != nil {
                self.hud.show(near: point)
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
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Pluck"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        onboardingWindow = window
        onboardingState.beginPolling()
    }

    // Fires for any close path — red traffic light, "Skip for now", or the
    // "Start using Pluck" CTA — so we always stop polling and (if both
    // permissions are now granted) start the engine AND mark onboarding
    // confirmed. The grant is what matters; the specific button is cosmetic.
    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow,
              closing === onboardingWindow else { return }
        onboardingState.stopPolling()
        onboardingWindow = nil
        if onboardingState.allGranted {
            onboardingCompleted = true
            startEngineIfPossible()
        }
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
