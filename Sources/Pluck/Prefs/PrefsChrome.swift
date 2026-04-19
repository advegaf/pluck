import SwiftUI

/// Top-level Preferences shell: background, sidebar, content. Fixed 700×500.
struct PrefsChrome: View {
    @State private var selected: PrefsTab = .general
    let blocklist: Blocklist

    var body: some View {
        ZStack {
            Palette.background
                .ignoresSafeArea()
            HStack(spacing: 0) {
                PrefsSidebar(selected: $selected)
                    .frame(width: Metrics.sidebarWidth, alignment: .top)
                Rectangle()
                    .fill(Palette.separator)
                    .frame(width: 1)
                PrefsContent(tab: selected, blocklist: blocklist)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: Metrics.windowWidth, height: Metrics.windowHeight)
        .tint(Palette.accent)
    }
}
