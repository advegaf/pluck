import SwiftUI
import AppKit

@main
struct PluckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Pluck", systemImage: "scissors") {
            MenuContent(shell: appDelegate.shell)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            if let shell = appDelegate.shell {
                PrefsView(blocklist: shell.blocklist)
            } else {
                ProgressView()
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var shell: AppShell?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let shell = AppShell()
        self.shell = shell
        shell.bootstrap()
    }
}

private struct MenuContent: View {
    @State private var paused: Bool = false
    var shell: AppShell?

    var body: some View {
        Button(paused ? "Resume Pluck" : "Pause Pluck") {
            paused.toggle()
            shell?.isPaused = paused
        }
        Divider()
        SettingsLink { Text("Preferences…") }
            .keyboardShortcut(",")
        Button("Show Onboarding…") { shell?.showOnboarding() }
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
