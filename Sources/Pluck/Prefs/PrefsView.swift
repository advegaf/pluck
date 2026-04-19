import SwiftUI
import ServiceManagement

struct PrefsView: View {
    @AppStorage("pluck.holdDelayMs") private var holdDelayMs: Int = 150
    @AppStorage("pluck.hudEnabled") private var hudEnabled: Bool = true
    @AppStorage("pluck.launchAtLogin") private var launchAtLogin: Bool = false

    let blocklist: Blocklist
    @State private var blocklistEntries: [String] = []
    @State private var selectedBlocklistRow: String?

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gearshape") }
            blocklistTab.tabItem { Label("Blocklist", systemImage: "nosign") }
        }
        .frame(width: 520, height: 360)
        .onAppear { blocklistEntries = blocklist.bundleIDs }
    }

    private var generalTab: some View {
        Form {
            Section("Gesture") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Hold delay")
                        Spacer()
                        Text("\(holdDelayMs) ms").foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(holdDelayMs) },
                            set: { holdDelayMs = Int($0.rounded()) }
                        ),
                        in: 100...400,
                        step: 10
                    )
                    Text("How long you must hold mouse-down on a selection before Pluck copies it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Feedback") {
                Toggle("Show \"Copied\" HUD near cursor", isOn: $hudEnabled)
            }
            Section("Launch") {
                Toggle("Launch Pluck at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        applyLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 0)
    }

    private var blocklistTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Apps in this list are ignored by Pluck.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset to Defaults") {
                    blocklist.resetToDefaults()
                    blocklistEntries = blocklist.bundleIDs
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            List(blocklistEntries, id: \.self, selection: $selectedBlocklistRow) { id in
                Text(id).font(.system(size: 12, design: .monospaced))
            }
            .listStyle(.inset)

            HStack {
                Button {
                    pickAppAndAdd()
                } label: {
                    Image(systemName: "plus")
                }
                Button {
                    if let sel = selectedBlocklistRow {
                        blocklist.remove(sel)
                        blocklistEntries = blocklist.bundleIDs
                        selectedBlocklistRow = nil
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedBlocklistRow == nil)
                Spacer()
            }
            .padding(12)
            .buttonStyle(.bordered)
        }
    }

    private func pickAppAndAdd() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let id = bundle.bundleIdentifier {
                blocklist.add(id)
                blocklistEntries = blocklist.bundleIDs
            }
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
        } catch {
            NSLog("Pluck: failed to update login item: \(error)")
        }
    }
}
