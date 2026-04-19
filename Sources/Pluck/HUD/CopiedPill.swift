import SwiftUI

/// The "✓ Copied" HUD rendered as Apple Liquid Glass (macOS 26). A single
/// capsule is wrapped in a `GlassEffectContainer` and tagged with a shared
/// `glassEffectID` so SwiftUI morphs its frame fluidly between the 22×22
/// droplet and the 92×30 pill. Content (checkmark + label) crossfades in
/// with staggered offsets so the meaning "fills" the glass as it widens.
struct CopiedPill: View {
    var isVisible: Bool
    var label: String = "Copied"

    @Namespace private var glassNamespace

    static let collapsedSize = CGSize(width: 22, height: 22)
    static let expandedSize  = CGSize(width: 92, height: 30)

    var body: some View {
        GlassEffectContainer {
            // Content sits INSIDE the capsule. Padding drives size when
            // visible; when hidden, we clamp to a 22×22 droplet frame via
            // .frame and fade the content out.
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(isVisible ? 1 : 0)
                    // Check appears at ~30% of the 400ms spring → 120ms in.
                    .animation(.smooth(duration: 0.40).delay(isVisible ? 0.120 : 0), value: isVisible)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(isVisible ? 1 : 0)
                    .fixedSize()
                    // Label appears at ~60% → 240ms in.
                    .animation(.smooth(duration: 0.40).delay(isVisible ? 0.240 : 0), value: isVisible)
            }
            .padding(.horizontal, isVisible ? 12 : 0)
            .padding(.vertical, isVisible ? 7 : 0)
            .frame(
                width:  isVisible ? nil : Self.collapsedSize.width,
                height: isVisible ? nil : Self.collapsedSize.height
            )
            // HIG: glass effect AFTER layout modifiers. Capsule renders as
            // a circle when width == height (the droplet state).
            .glassEffect(.regular, in: .capsule)
            .glassEffectID("pill", in: glassNamespace)
        }
        .foregroundStyle(.primary)
        .animation(.smooth(duration: 0.40), value: isVisible)
    }
}

#Preview("Hidden → Visible") {
    struct Demo: View {
        @State var visible = false
        var body: some View {
            VStack(spacing: 30) {
                CopiedPill(isVisible: visible)
                Button(visible ? "Hide" : "Show") { visible.toggle() }
            }
            .padding(60)
            .frame(width: 300, height: 200)
            .background(Color.black)
        }
    }
    return Demo()
}
