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

struct POSEntityDetailRoute: Identifiable, Equatable {
    let id: String
    let title: String
    var initialSection: POSEntityDetailSection = .overview

    static func == (lhs: POSEntityDetailRoute, rhs: POSEntityDetailRoute) -> Bool {
        lhs.id == rhs.id && lhs.initialSection == rhs.initialSection
    }
}

struct MainTabView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var tab: POSTab = .home
    @State private var webSheet: WebSheetRoute?
    @State private var entityDetail: POSEntityDetailRoute?
    @State private var showCVHub = false
    @State private var showJobScout = false

    private var nav: POSNavigationActions {
        POSNavigationActions(
            onOpen: openRoute,
            onSwitchTab: { tab = $0 },
            onLegacyScreen: { webSheet = $0.embedded() },
            onOpenCV: { showCVHub = true },
            onOpenJobScout: { showJobScout = true }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            POSAppHeader(
                title: tab.headerTitle,
                initials: session.userInitials(),
                onAvatarTap: { openRoute(.path("/settings", title: "Profile")) },
                onSettingsTap: { tab = .more }
            )

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
                    POSMoreView(nav: nav)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            POSBottomTabBar(selection: $tab)
        }
        .background(POSTheme.background)
        .sheet(item: $webSheet) { route in
            LegacyWebScreen(route: route) { webSheet = nil }
        }
        .fullScreenCover(item: $entityDetail) { route in
            POSEntityDetailView(
                entityId: route.id,
                initialSection: route.initialSection,
                onOpenEntity: { id, title in
                    entityDetail = POSEntityDetailRoute(id: id, title: title)
                },
                onClose: { entityDetail = nil }
            )
            .environmentObject(session)
        }
        .sheet(isPresented: $showCVHub) {
            POSCVHubView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showJobScout) {
            POSJobScoutView()
                .environmentObject(session)
        }
        .task { await session.refreshUser() }
    }

    private func openRoute(_ route: WebSheetRoute) {
        POSHaptics.light()
        if let entityId = route.entityId {
            entityDetail = POSEntityDetailRoute(
                id: entityId,
                title: route.title,
                initialSection: route.entitySection ?? .overview
            )
        } else {
            webSheet = route.embedded()
        }
    }
}

struct WebSheetRoute: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
    var entitySection: POSEntityDetailSection?

    var entityId: String? {
        let path = url.path
        guard path.contains("/entities/") else { return nil }
        let raw = path.components(separatedBy: "/entities/").last ?? ""
        return raw.split(separator: "/").first.map(String.init)
    }

    func embedded() -> WebSheetRoute {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return self }
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == "embed" }) {
            items.append(URLQueryItem(name: "embed", value: "1"))
        }
        components.queryItems = items
        return WebSheetRoute(
            url: components.url ?? url,
            title: title,
            entitySection: entitySection
        )
    }

    static func entity(_ id: String, title: String, section: POSEntityDetailSection = .overview) -> WebSheetRoute {
        WebSheetRoute(
            url: PersonalOSAppConfig.frontendPath("/entities/\(id)"),
            title: title,
            entitySection: section
        )
    }

    static func path(_ path: String, title: String) -> WebSheetRoute {
        WebSheetRoute(url: PersonalOSAppConfig.frontendPath(path), title: title)
            .embedded()
    }
}

typealias WebOpenHandler = (WebSheetRoute) -> Void
