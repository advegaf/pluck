import AppKit
import SwiftUI

@MainActor
final class HUDPresenter {
    private var panel: NSPanel?
    private var dismissWork: DispatchWorkItem?

    private let fadeIn: TimeInterval  = 0.20
    private let hold: TimeInterval    = 1.00
    private let fadeOut: TimeInterval = 0.30

    /// `anchor` is used only to pick the screen containing the cursor;
    /// the pill itself sits at bottom-center of that screen, matching
    /// macOS system HUDs.
    func show(near anchor: CGPoint) {
        let panel = ensurePanel()
        let pillSize = panel.contentView?.fittingSize
            ?? CGSize(width: 100, height: 34)
        let screen = NSScreen.containing(anchor) ?? NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame ?? .zero
        let origin = HUDGeometry.panelOrigin(pillSize: pillSize, screenFrame: frame)

        panel.setFrame(NSRect(origin: origin, size: pillSize), display: true)

        dismissWork?.cancel()

        if !panel.isVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = fadeIn
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }
        // If already visible: leave alpha at 1, just extend the hold below.

        scheduleDismiss()
    }

    private func scheduleDismiss() {
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.fadeOutAndHide() }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hold, execute: work)
    }

    private func fadeOutAndHide() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = fadeOut
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak panel] in
            MainActor.assumeIsolated { panel?.orderOut(nil) }
        })
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let host = NSHostingController(rootView: CopiedPill())
        host.sizingOptions = [.preferredContentSize]
        host.view.setFrameSize(host.view.fittingSize)

        let panel = ClickThroughPanel(
            contentRect: NSRect(origin: .zero, size: host.view.fittingSize),
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
