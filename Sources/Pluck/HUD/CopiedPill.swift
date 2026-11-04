import SwiftUI

/// The "Copied 42 characters ✓" HUD — a static Liquid Glass capsule. No
/// morph, no namespace, no container. Panel alpha fades it in and out (see
/// `HUDPresenter`), matching how volume/AirPods/focus HUDs behave.
struct CopiedPill: View {
    /// Characters as a person counts them (grapheme clusters), so an emoji
    /// with a skin-tone modifier counts as one.
    var characterCount: Int

    /// Pure, so it is unit-tested apart from SwiftUI.
    static func label(characterCount: Int) -> String {
        let unit = characterCount == 1 ? "character" : "characters"
        return "Copied \(characterCount.formatted()) \(unit)"
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(Self.label(characterCount: characterCount))
                .monospacedDigit()
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
    CopiedPill(characterCount: 42)
        .padding(40)
        .background(Color.black)
}
