import SwiftUI

struct PermissionCard: View {
    let title: String
    let subtitle: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: granted ? .semibold : .regular))
                .foregroundStyle(granted ? Palette.accent : Palette.textTertiary)
                .frame(width: 28, height: 28)
                .animation(Motion.easeOut, value: granted)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.bodyEmphasized())
                    .tracking(Tracking.body)
                    .foregroundStyle(Palette.textPrimary)
                Text(subtitle)
                    .font(Typography.caption())
                    .tracking(Tracking.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button(action: action) {
                Text(granted ? "Granted" : "Open Settings")
                    .font(Typography.body())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .foregroundStyle(granted ? Palette.textTertiary : Palette.accent)
                    .overlay(
                        Capsule().stroke(granted ? Palette.separator : Palette.accent,
                                         lineWidth: 1)
                    )
            }
            .buttonStyle(.pluckPress)
            .disabled(granted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(Palette.surface)
        )
    }
}
