import SwiftUI
import AppKit
import ServiceManagement

struct PrefsContent: View {
    let tab: PrefsTab
    let blocklist: Blocklist

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                header
                switch tab {
                case .general:   GeneralTab()
                case .blocklist: BlocklistTab(blocklist: blocklist)
                case .about:     AboutTab()
                }
                Spacer(minLength: 0)
            }
            .padding(Metrics.contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        Text(tab.title)
            .font(Typography.title())
            .tracking(Tracking.title)
            .foregroundStyle(Palette.textPrimary)
            .padding(.bottom, 2)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @AppStorage("pluck.holdDelayMs") private var holdDelayMs: Int = 150

    var body: some View {
        PrefsSection("Gesture") {
            PrefsRow("Hold delay",
                     description: "Time to hold the click on a selection before Pluck copies.") {
                HStack(spacing: 10) {
                    Slider(value: Binding(
                        get: { Double(holdDelayMs) },
                        set: { holdDelayMs = Int($0.rounded()) }
                    ), in: 100...400, step: 10)
                    .frame(width: 160)
                    Text("\(holdDelayMs) ms")
                        .font(Typography.body().monospacedDigit())
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 62, alignment: .trailing)
                }
            }
        }

        PrefsSection("Launch") {
            LaunchAtLoginRow()
        }
    }
}

private struct LaunchAtLoginRow: View {
    @State private var enabled: Bool = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        PrefsRow("Open Pluck at login") {
            Toggle("", isOn: $enabled)
                .labelsHidden()
                .onChange(of: enabled) { _, newValue in
                    apply(newValue)
                }
        }
    }

    private func apply(_ newValue: Bool) {
        let service = SMAppService.mainApp
        do {
            if newValue, service.status != .enabled {
                try service.register()
            } else if !newValue, service.status == .enabled {
                try service.unregister()
            }
        } catch {
            NSLog("Pluck: login-item update failed: \(error)")
            // Reflect the truth after the failure.
            enabled = (service.status == .enabled)
        }
    }
}

// MARK: - Blocklist

private struct BlocklistTab: View {
    let blocklist: Blocklist

    @State private var entries: [String] = []
    @State private var selection: String?

    var body: some View {
        PrefsSection(
            "Apps Pluck ignores",
            description: "Hold-click is silently skipped in these apps. Add any app where the gesture misbehaves."
        ) {
            VStack(spacing: 0) {
                if entries.isEmpty {
                    Text("No apps blocked.")
                        .font(Typography.body())
                        .tracking(Tracking.body)
                        .foregroundStyle(Palette.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                } else {
                    ForEach(Array(entries.enumerated()), id: \.element) { idx, id in
                        if idx > 0 { PrefsSeparator() }
                        BlocklistRow(id: id, isSelected: selection == id) {
                            selection = (selection == id) ? nil : id
                        }
                    }
                }

                PrefsSeparator()
                HStack(spacing: 8) {
                    Button { pickAppAndAdd() } label: {
                        Image(systemName: "plus")
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.pluckPress)

                    Button {
                        if let sel = selection {
                            blocklist.remove(sel)
                            entries = blocklist.bundleIDs
                            selection = nil
                        }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.pluckPress)
                    .disabled(selection == nil)

                    Spacer()

                    Button("Reset to defaults") {
                        blocklist.resetToDefaults()
                        entries = blocklist.bundleIDs
                        selection = nil
                    }
                    .buttonStyle(.pluckPress)
                    .foregroundStyle(Palette.accent)
                    .font(Typography.body())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .onAppear { entries = blocklist.bundleIDs }
    }

    private func pickAppAndAdd() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url,
           let bundle = Bundle(url: url), let id = bundle.bundleIdentifier {
            blocklist.add(id)
            entries = blocklist.bundleIDs
        }
    }
}

private struct BlocklistRow: View {
    let id: String
    let isSelected: Bool
    let toggle: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(id)
                    .font(Typography.mono())
                    .foregroundStyle(isSelected ? Palette.onAccent : Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pluckPress)
        .onHover { hovering = $0 }
        .animation(Motion.fast, value: hovering)
        .animation(Motion.fast, value: isSelected)
    }

    @ViewBuilder private var background: some View {
        if isSelected {
            Palette.accent
        } else if hovering {
            Palette.surfaceHover
        } else {
            Color.clear
        }
    }
}

// MARK: - About

private struct AboutTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "scissors")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pluck")
                    .font(Typography.title())
                    .tracking(Tracking.title)
                    .foregroundStyle(Palette.textPrimary)
                Text("Version 0.1.0")
                    .font(Typography.caption())
                    .tracking(Tracking.caption)
                    .foregroundStyle(Palette.textSecondary)
            }

            Text("Hold-click to copy selected text, anywhere on macOS.")
                .font(Typography.subtitle())
                .foregroundStyle(Palette.textSecondary)
                .frame(maxWidth: 420, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    if let url = URL(string: "https://github.com/") { NSWorkspace.shared.open(url) }
                } label: {
                    Text("GitHub")
                        .font(Typography.body())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(Palette.accent)
                        .overlay(
                            Capsule().stroke(Palette.accent, lineWidth: 1)
                        )
                }
                .buttonStyle(.pluckPress)

                Button {
                    if let url = URL(string: "mailto:feedback@pluck.app") { NSWorkspace.shared.open(url) }
                } label: {
                    Text("Send feedback")
                        .font(Typography.body())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(Palette.onAccent)
                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: Metrics.chipRadius,
                                                                          style: .continuous))
                }
                .buttonStyle(.pluckPress)
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }
}
