import SwiftUI
import AppKit

/// Owns the one `AppShell` instance for the whole process. Eagerly
/// instantiated so it is always non-nil when a Scene body evaluates; this
/// removes the need for SwiftUI to observe an optional on the AppDelegate
/// (which proved unreliable in practice for the Settings scene).
@MainActor
enum PluckRoot {
    static let shell = AppShell()
}

@main
struct PluckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Pluck", systemImage: "scissors") {
            MenuContent(shell: PluckRoot.shell)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PrefsChrome(blocklist: PluckRoot.shell.blocklist)
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        PluckRoot.shell.bootstrap()
    }
}

private struct MenuContent: View {
    @State private var paused: Bool = false
    var shell: AppShell

    var body: some View {
        Button(paused ? "Resume Pluck" : "Pause Pluck") {
            paused.toggle()
            shell.isPaused = paused
        }
        Divider()
        SettingsLink { Text("Preferences…") }
            .keyboardShortcut(",")
        Button("Show Onboarding…") { shell.showOnboarding() }
        Divider()
        Button("About Pluck") { showAbout() }
        Button("Quit Pluck") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate()
    }
}
