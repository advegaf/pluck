import SwiftUI

/// The "✓ Copied" pill. Tokens pulled from DESIGN.md (Apple system):
/// SF Pro Rounded Semibold 13pt, ultraThinMaterial, 14pt radius,
/// subtle diffused shadow.
struct CopiedPill: View {
    var label: String = "Copied"

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 3)
        .foregroundStyle(.primary)
        .fixedSize()
    }
}

#Preview {
    CopiedPill()
        .padding(40)
        .background(Color.black)
}
