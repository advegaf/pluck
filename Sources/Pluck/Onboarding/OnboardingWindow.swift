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
        ZStack {
            Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                VStack(spacing: 10) {
                    Text("Welcome to Pluck")
                        .font(Typography.hero())
                        .tracking(Tracking.hero)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Grant these two permissions once. Then hold-click any selection to copy.")
                        .font(Typography.subtitle())
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer().frame(height: 36)

                VStack(spacing: 12) {
                    PermissionCard(
                        title: "Accessibility",
                        subtitle: "Lets Pluck read the selected text from the app you click in.",
                        granted: state.accessibilityGranted,
                        action: { PermissionChecks.openSettings(for: .accessibility) }
                    )
                    PermissionCard(
                        title: "Input Monitoring",
                        subtitle: "Lets Pluck notice the hold-click gesture without intercepting your clicks.",
                        granted: state.inputMonitoringGranted,
                        action: { PermissionChecks.openSettings(for: .inputMonitoring) }
                    )
                }
                .frame(maxWidth: 480)

                Spacer(minLength: 0)

                HStack {
                    Button("Skip for now") { onFinish() }
                        .buttonStyle(.pluckPress)
                        .foregroundStyle(Palette.textTertiary)
                        .font(Typography.body())

                    Spacer()

                    Button {
                        onFinish()
                    } label: {
                        Text("Start using Pluck")
                            .font(Typography.body())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .foregroundStyle(Palette.onAccent)
                            .background(
                                state.allGranted ? Palette.accent : Palette.accent.opacity(0.4),
                                in: RoundedRectangle(cornerRadius: Metrics.chipRadius,
                                                     style: .continuous)
                            )
                    }
                    .buttonStyle(.pluckPress)
                    .disabled(!state.allGranted)
                    .animation(Motion.easeOut, value: state.allGranted)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 32)
        }
        .frame(width: Metrics.windowWidth, height: Metrics.windowHeight)
        .tint(Palette.accent)
    }
}
