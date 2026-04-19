import AppKit
import SwiftUI

@MainActor
final class HUDPresenter {
    private var panel: NSPanel?
    private var hostingController: NSHostingController<CopiedPill>?
    private var dismissWork: DispatchWorkItem?

    private let fadeIn: TimeInterval = 0.08
    private let hold: TimeInterval = 0.45
    private let fadeOut: TimeInterval = 0.12

    func show(near anchor: CGPoint) {
        let panel = ensurePanel()
        let pillSize = panel.contentView?.fittingSize ?? CGSize(width: 108, height: 30)
        let screen = NSScreen.containing(anchor) ?? NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame ?? .zero

        let origin = HUDGeometry.panelOrigin(
            anchor: anchor,
            pillSize: pillSize,
            screenFrame: frame
        )
        panel.setFrame(NSRect(origin: origin, size: pillSize), display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = fadeIn
            panel.animator().alphaValue = 1
        }

        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.fadeOutAndHide()
            }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeIn + hold, execute: work)
    }

    private func fadeOutAndHide() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = fadeOut
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak panel] in
            // `runAnimationGroup`'s completion runs on the main thread.
            MainActor.assumeIsolated {
                panel?.orderOut(nil)
            }
        })
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let root = CopiedPill()
        let host = NSHostingController(rootView: root)
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
        self.hostingController = host
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
