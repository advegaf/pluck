import SwiftUI

/// Labeled card. Header is an uppercased caption above the card, matching
/// macOS System Settings idiom.
struct PrefsSection<Content: View>: View {
    let title: String?
    let description: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String? = nil,
         description: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased())
                    .font(Typography.sectionHeader())
                    .tracking(0.6)
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.horizontal, 2)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardRadius,
                                 style: .continuous)
                    .fill(Palette.surface)
            )

            if let description {
                Text(description)
                    .font(Typography.caption())
                    .tracking(Tracking.caption)
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Horizontal hairline separator between rows inside a section card.
/// Inset 16 pt from the leading edge so it lives under the labels.
struct PrefsSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}
