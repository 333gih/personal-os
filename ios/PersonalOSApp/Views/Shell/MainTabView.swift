import SwiftUI

struct POSAppHeader: View {
    let title: String
    let initials: String
    var onAvatarTap: (() -> Void)?
    var onSettingsTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onAvatarTap?()
            } label: {
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                    .frame(width: 36, height: 36)
                    .background(POSTheme.primary.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.posDisplay(17))
                .foregroundStyle(POSTheme.foreground)
                .lineLimit(1)

            Spacer()

            Button {
                onSettingsTap?()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body)
                    .foregroundStyle(POSTheme.primaryDark)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(POSTheme.background.opacity(0.95))
    }
}

struct POSBottomTabBar: View {
    @Binding var selection: POSTab

    var body: some View {
        HStack {
            ForEach(POSTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 20, weight: selection == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                        if selection == tab {
                            Circle()
                                .fill(POSTheme.primaryDark)
                                .frame(width: 4, height: 4)
                        } else {
                            Circle().fill(.clear).frame(width: 4, height: 4)
                        }
                    }
                    .foregroundStyle(selection == tab ? POSTheme.primaryDark : POSTheme.muted)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
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
    @State private var showStartup = false

    var body: some View {
        VStack(spacing: 0) {
            POSAppHeader(
                title: tab.headerTitle,
                initials: session.userInitials(),
                onSettingsTap: { tab = .more }
            )

            Group {
                switch tab {
                case .home:
                    HomeView(onOpen: openWeb)
                case .work:
                    WorkView(onOpen: openWeb)
                case .learning:
                    LearningView(onOpen: openWeb)
                case .search:
                    SearchView(onOpen: openWeb)
                case .more:
                    MoreView(onOpen: openWeb, onSignOut: { session.signOut() }, onOpenStartup: { showStartup = true })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            POSBottomTabBar(selection: $tab)
        }
        .background(POSTheme.background)
        .sheet(item: $webSheet) { route in
            NavigationStack {
                WebAppView(startURL: route.url)
                    .navigationTitle(route.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { webSheet = nil }
                        }
                    }
            }
        }
        .sheet(isPresented: $showStartup) {
            NavigationStack {
                StartupView(onOpen: openWeb)
                    .navigationTitle("Startup Ecosystem")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showStartup = false }
                        }
                    }
            }
            .environmentObject(session)
        }
        .task { await session.refreshUser() }
    }

    private func openWeb(_ route: WebSheetRoute) {
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
