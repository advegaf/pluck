import SwiftUI

enum PrefsTab: String, CaseIterable, Identifiable, Sendable {
    case general, blocklist, about
    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .blocklist: return "Blocklist"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .blocklist: return "nosign"
        case .about: return "info.circle"
        }
    }
}

struct PrefsSidebar: View {
    @Binding var selected: PrefsTab

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Pluck")
                .font(Typography.bodyEmphasized())
                .tracking(Tracking.body)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 14)

            ForEach(PrefsTab.allCases) { tab in
                PrefsSidebarRow(tab: tab, isSelected: tab == selected) {
                    selected = tab
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct PrefsSidebarRow: View {
    let tab: PrefsTab
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .regular))
                    .frame(width: 18, alignment: .center)
                Text(tab.title)
                    .font(Typography.body())
                    .tracking(Tracking.body)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? Palette.onAccent : Palette.textPrimary)
            .padding(.horizontal, 10)
            .frame(height: Metrics.sidebarRowHeight)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.chipRadius,
                                        style: .continuous))
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
