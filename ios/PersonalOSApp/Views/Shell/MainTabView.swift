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

struct POSLearningLessonRoute: Identifiable, Equatable {
    let id: String
    let title: String
}

struct MainTabView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: POSTab = .home
    @State private var webSheet: WebSheetRoute?
    @State private var entityDetail: POSEntityDetailRoute?
    @State private var showCVHub = false
    @State private var showJobScout = false
    @State private var showWorkImport = false
    @State private var showWorkAdd = false
    @State private var showWorkHub = false
    @State private var showStartup = false
    @State private var showStartupHub = false
    @State private var showStartupAdd = false
    @State private var workReloadToken = UUID()
    @State private var startupReloadToken = UUID()
    @State private var showLearningHub = false
    @State private var showLearningAdd = false
    @State private var showLearningCoach = false
    @State private var showLearningSchedule = false
    @State private var showNotificationLog = false
    @State private var showInterviewPrep = false
    @State private var learningTrack: POSLearningTrack = .dsa
    @State private var learningCoachEntityID: String?
    @State private var learningCoachTopic = ""
    @State private var learningReloadToken = UUID()
    @State private var learningLesson: POSLearningLessonRoute?

    private var nav: POSNavigationActions {
        POSNavigationActions(
            onOpen: openRoute,
            onSwitchTab: { tab = $0 },
            onLegacyScreen: { webSheet = $0.embedded() },
            onOpenCV: { showCVHub = true },
            onOpenJobScout: { showJobScout = true },
            onOpenWorkImport: { showWorkImport = true },
            onOpenWorkAdd: { showWorkAdd = true },
            onOpenWorkHub: { showWorkHub = true },
            onOpenStartup: { showStartup = true },
            onOpenStartupHub: { showStartupHub = true },
            onOpenStartupAdd: { showStartupAdd = true },
            onOpenLearningHub: { showLearningHub = true },
            onOpenLearningAdd: { track in
                learningTrack = track
                showLearningAdd = true
            },
            onOpenLearningCoach: { track, entityID, topic in
                learningTrack = track
                learningCoachEntityID = entityID
                learningCoachTopic = topic
                showLearningCoach = true
            },
            onOpenLearningLesson: { id, title in
                learningLesson = POSLearningLessonRoute(id: id, title: title)
            },
            onOpenInterviewPrep: { showInterviewPrep = true }
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
                        .id(workReloadToken)
                case .learning:
                    LearningView(nav: nav)
                        .id(learningReloadToken)
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
        .fullScreenCover(item: $learningLesson) { route in
            POSLearningLessonView(
                entityId: route.id,
                onOpenModule: { id, title in
                    learningLesson = POSLearningLessonRoute(id: id, title: title)
                },
                onClose: { learningLesson = nil }
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
        .sheet(isPresented: $showWorkImport) {
            POSWorkImportView { projectId, title in
                workReloadToken = UUID()
                entityDetail = POSEntityDetailRoute(id: projectId, title: title, initialSection: .architecture)
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $showWorkAdd) {
            POSWorkAddView { entityId, title in
                workReloadToken = UUID()
                entityDetail = POSEntityDetailRoute(id: entityId, title: title)
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $showWorkHub) {
            POSWorkHubMenu(
                onAddEntry: { showWorkAdd = true },
                onImport: { showWorkImport = true },
                onCV: { showCVHub = true },
                onJobScout: { showJobScout = true },
                onInterviewPrep: { showInterviewPrep = true },
                onCapture: { nav.captureNote() }
            )
        }
        .sheet(isPresented: $showStartup) {
            NavigationStack {
                StartupView(nav: nav)
                    .environmentObject(session)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showStartup = false }
                        }
                    }
            }
            .id(startupReloadToken)
        }
        .sheet(isPresented: $showStartupHub) {
            POSStartupHubMenu(
                onAddEntry: { showStartupAdd = true },
                onOpenBoard: { showStartup = true },
                onCapture: { nav.captureNote() }
            )
        }
        .sheet(isPresented: $showStartupAdd) {
            POSStartupAddView { entityId, title in
                startupReloadToken = UUID()
                showStartup = true
                entityDetail = POSEntityDetailRoute(id: entityId, title: title)
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $showLearningHub) {
            POSLearningHubMenu(
                onAddEntry: { showLearningAdd = true },
                onCoach: { showLearningCoach = true },
                onSchedule: { showLearningSchedule = true },
                onNotificationLog: { showNotificationLog = true },
                onOpenBoard: { webSheet = WebSheetRoute.path("/learning", title: "Learning").embedded() },
                onCapture: { nav.captureNote() }
            )
        }
        .sheet(isPresented: $showLearningAdd) {
            POSLearningAddView(track: learningTrack) { entityId, title in
                learningReloadToken = UUID()
                learningLesson = POSLearningLessonRoute(id: entityId, title: title)
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $showLearningCoach) {
            POSLearningCoachView(track: learningTrack, entityID: learningCoachEntityID, initialTopic: learningCoachTopic)
                .environmentObject(session)
        }
        .sheet(isPresented: $showLearningSchedule) {
            POSLearningScheduleSettingsView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showNotificationLog) {
            POSNotificationLogView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showInterviewPrep) {
            POSInterviewPrepView()
                .environmentObject(session)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await session.refreshSessionIfNeeded(force: false)
            }
        }
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
