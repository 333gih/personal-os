import SwiftUI

struct POSAppHeader: View {
    let title: String
    let initials: String
    var showsSettings: Bool = true
    var onAvatarTap: (() -> Void)?
    var onSettingsTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                POSHaptics.light()
                onAvatarTap?()
            } label: {
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                    .frame(width: 36, height: 36)
                    .background(POSTheme.primary.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(POSPressButtonStyle())

            Spacer()

            Text(title)
                .font(.posDisplay(17))
                .foregroundStyle(POSTheme.ink)
                .lineLimit(1)

            Spacer()

            if showsSettings {
                Button {
                    POSHaptics.light()
                    onSettingsTap?()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body.weight(.medium))
                        .foregroundStyle(POSTheme.primaryDark)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(POSPressButtonStyle())
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(POSTheme.background.opacity(0.96))
    }
}

struct POSBottomTabBar: View {
    @Binding var selection: POSTab

    var body: some View {
        HStack {
            ForEach(POSTab.allCases) { tab in
                Button {
                    POSHaptics.selection()
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 19, weight: selection == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                        Circle()
                            .fill(selection == tab ? POSTheme.primaryDark : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .foregroundStyle(selection == tab ? POSTheme.primaryDark : POSTheme.muted)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(POSTheme.card)
        .overlay(alignment: .top) { Divider() }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var tab: POSTab = .home
    @State private var webSheet: WebSheetRoute?

    private var nav: POSNavigationActions {
        POSNavigationActions(
            onOpen: openWeb,
            onSwitchTab: { tab = $0 },
            onLegacyScreen: { webSheet = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if tab != .more {
                POSAppHeader(
                    title: tab.headerTitle,
                    initials: session.userInitials(),
                    onAvatarTap: { openWeb(.path("/settings", title: "Profile")) },
                    onSettingsTap: { tab = .more }
                )
            }

            Group {
                switch tab {
                case .home:
                    HomeView(nav: nav)
                case .work:
                    WorkView(nav: nav)
                case .learning:
                    LearningView(nav: nav)
                case .search:
                    SearchView(nav: nav)
                case .more:
                    LegacyWebTabView(path: "/settings")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            POSBottomTabBar(selection: $tab)
        }
        .background(POSTheme.background)
        .sheet(item: $webSheet) { route in
            LegacyWebScreen(route: route) { webSheet = nil }
        }
        .task { await session.refreshUser() }
    }

    private func openWeb(_ route: WebSheetRoute) {
        POSHaptics.light()
        webSheet = route
    }
}

struct WebSheetRoute: Identifiable {
    let id = UUID()
    let url: URL
    let title: String

    static func entity(_ id: String, title: String) -> WebSheetRoute {
        WebSheetRoute(url: PersonalOSAppConfig.frontendPath("/entities/\(id)"), title: title)
    }

    static func path(_ path: String, title: String) -> WebSheetRoute {
        WebSheetRoute(url: PersonalOSAppConfig.frontendPath(path), title: title)
    }
}

typealias WebOpenHandler = (WebSheetRoute) -> Void
