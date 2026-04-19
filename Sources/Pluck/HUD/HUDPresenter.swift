import AppKit
import SwiftUI

/// Observable model the SwiftUI host reads. The presenter flips
/// `isVisible` to drive the Liquid Glass morph; SwiftUI handles the
/// capsule frame interpolation and content stagger.
@MainActor
@Observable
final class HUDModel {
    var isVisible: Bool = false
}

struct HUDHostView: View {
    @Bindable var model: HUDModel

    var body: some View {
        // The hosting controller is pinned to the pill's expanded size so
        // NSHostingController never resizes the panel out from under us.
        // The SwiftUI content draws within this box; the capsule itself
        // animates its shape between droplet and pill.
        CopiedPill(isVisible: model.isVisible)
            .frame(
                width: CopiedPill.expandedSize.width,
                height: CopiedPill.expandedSize.height
            )
    }
}

@MainActor
final class HUDPresenter {
    private var panel: NSPanel?
    private let model = HUDModel()
    private var dismissWork: DispatchWorkItem?

    /// Time the pill stays fully expanded before the reverse morph begins.
    private let hold: TimeInterval = 0.900
    /// Duration of the reverse spring — after this, orderOut the panel.
    /// Matches the 700ms `.smooth` spring in `CopiedPill`.
    private let exitDuration: TimeInterval = 0.700

    /// `anchor` is used only to pick the screen the user is working on;
    /// the pill itself sits at bottom-center of that screen. Matches how
    /// macOS's own HUDs (volume, AirPods, focus) behave.
    func show(near anchor: CGPoint) {
        let panel = ensurePanel()
        let pillSize = CopiedPill.expandedSize
        let screen = NSScreen.containing(anchor) ?? NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame ?? .zero
        let origin = HUDGeometry.panelOrigin(pillSize: pillSize, screenFrame: frame)

        // Rapid-repeat: HUD already on screen → cancel the pending exit
        // and extend the hold. Never restart the morph mid-visible.
        //
        // Note: the morph plays regardless of `accessibilityReduceMotion`.
        // Deliberate product choice — the HUD is brief (∼950ms) and the
        // morph is the product identity.
        if panel.isVisible && model.isVisible {
            dismissWork?.cancel()
            scheduleExit()
            return
        }

        panel.setFrame(NSRect(origin: origin, size: pillSize), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        model.isVisible = true
        scheduleExit()
    }

    private func scheduleExit() {
        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.beginExit() }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hold, execute: work)
    }

    private func beginExit() {
        model.isVisible = false
        // After the reverse spring completes, order the panel out. The
        // panel is transparent so a brief delay doesn't show any chrome.
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.panel?.orderOut(nil) }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration, execute: work)
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let host = NSHostingController(rootView: HUDHostView(model: model))
        // Critical: prevent AppKit from resizing the panel to match SwiftUI's
        // preferred content size. Otherwise `setFrame` gets clobbered and
        // the panel ends up at AppKit's default position.
        host.sizingOptions = []
        host.view.setFrameSize(CopiedPill.expandedSize)

        let panel = ClickThroughPanel(
            contentRect: NSRect(origin: .zero, size: CopiedPill.expandedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.contentViewController = host

        self.panel = panel
        return panel
    }
}

private final class ClickThroughPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private extension NSScreen {
    static func containing(_ point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }
}
