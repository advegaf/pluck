import AppKit
import SwiftUI

@MainActor
@Observable
final class OnboardingState {
    var accessibilityGranted: Bool = PermissionChecks.accessibilityTrusted()
    var inputMonitoringGranted: Bool = PermissionChecks.inputMonitoringGranted()

    var allGranted: Bool { accessibilityGranted && inputMonitoringGranted }

    private var pollWork: DispatchWorkItem?

    func beginPolling() {
        pollWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.accessibilityGranted = PermissionChecks.accessibilityTrusted()
                self.inputMonitoringGranted = PermissionChecks.inputMonitoringGranted()
                if !self.allGranted {
                    self.beginPolling()
                }
            }
        }
        pollWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    func stopPolling() {
        pollWork?.cancel()
        pollWork = nil
    }
}

struct OnboardingView: View {
    @Bindable var state: OnboardingState
    var onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to Pluck")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Select text, hold a click, and it's copied. Grant the two permissions below to get started.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                permissionRow(
                    title: "Accessibility",
                    subtitle: "Lets Pluck read the selected text from the app you click in.",
                    granted: state.accessibilityGranted,
                    action: { PermissionChecks.openSettings(for: .accessibility) }
                )
                permissionRow(
                    title: "Input Monitoring",
                    subtitle: "Lets Pluck detect the hold-click gesture without intercepting your clicks.",
                    granted: state.inputMonitoringGranted,
                    action: { PermissionChecks.openSettings(for: .inputMonitoring) }
                )
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Done") { onFinish() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!state.allGranted)
            }
        }
        .padding(24)
        .frame(width: 460, height: 340)
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        subtitle: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(granted ? Color.accentColor : .secondary)
                .font(.system(size: 18))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Settings…", action: action)
                .buttonStyle(.bordered)
                .disabled(granted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
