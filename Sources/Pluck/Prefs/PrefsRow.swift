import SwiftUI

/// One labeled row inside a `PrefsSection`.
/// Title left, optional descriptive footnote underneath, control right.
struct PrefsRow<Control: View>: View {
    let title: String
    let description: String?
    @ViewBuilder var control: () -> Control

    init(_ title: String,
         description: String? = nil,
         @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.description = description
        self.control = control
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body())
                    .tracking(Tracking.body)
                    .foregroundStyle(Palette.textPrimary)
                if let description {
                    Text(description)
                        .font(Typography.caption())
                        .tracking(Tracking.caption)
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: Metrics.contentRowMinHeight)
    }
}
