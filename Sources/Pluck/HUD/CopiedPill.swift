import SwiftUI

/// The "Copied ✓" HUD — a static Liquid Glass capsule. No morph, no
/// namespace, no container. Panel alpha fades it in and out (see
/// `HUDPresenter`), matching how volume/AirPods/focus HUDs behave.
struct CopiedPill: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Copied")
                .font(.system(size: 13, weight: .semibold))
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect(.regular, in: .capsule)
        .foregroundStyle(.primary)
        .fixedSize()
    }
}

#Preview {
    CopiedPill()
        .padding(40)
        .background(Color.black)
}
