import SwiftUI

struct POSMoreView: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var modules: ModulesStore
    let nav: POSNavigationActions
    var onOpenModuleSettings: (() -> Void)?
    var onSelectTab: ((String) -> Void)?

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileCard
                    if !drawerModules.isEmpty {
                        section("Modules") {
                            ForEach(drawerModules, id: \.self) { moduleId in
                                drawerRow(moduleId)
                            }
                        }
                    }
                    section("Capture") {
                        drawerButton(title: "Inbox", subtitle: "Quick notes, links, and captures", icon: "tray.full", tint: POSTheme.primaryDark) {
                            nav.onOpen(.path("/inbox", title: "Inbox"))
                        }
                    }
                    section("Tools") {
                        if modules.isEnabled("work") {
                            drawerButton(title: "CV Transfer", subtitle: "Ideal resume, AI edit, PDF export", icon: "doc.richtext.fill", tint: POSTheme.primaryDark) {
                                nav.openCV()
                            }
                            drawerButton(title: "Job Scout", subtitle: "Daily skill-matched jobs", icon: "briefcase.fill", tint: POSTheme.focus) {
                                nav.openJobScout()
                            }
                        }
                    }
                    section("Account") {
                        drawerButton(title: "Module settings", subtitle: "Enable or disable app modules", icon: "puzzlepiece.extension.fill", tint: POSTheme.primaryDark) {
                            onOpenModuleSettings?()
                        }
                        drawerButton(title: "Settings", subtitle: "Profile and preferences", icon: "gearshape.fill", tint: POSTheme.muted) {
                            nav.onOpen(.path("/settings", title: "Settings"))
                        }
                    }
                    signOutButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var drawerModules: [String] {
        modules.drawerIds.filter { id in
            switch id {
            case "inbox", "settings": return false
            default: return modules.isEnabled(id) || id == "settings"
            }
        }
    }

    @ViewBuilder
    private func drawerRow(_ moduleId: String) -> some View {
        let tab = POSTabID.from(moduleId) ?? .dashboard
        let entry = modules.catalog.first(where: { $0.id == moduleId })
        drawerButton(
            title: entry?.label ?? tab.title,
            subtitle: entry?.description ?? "",
            icon: tab.systemImage,
            tint: POSTheme.focus
        ) {
            onSelectTab?(moduleId)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.posCaps())
                .foregroundStyle(POSTheme.muted)
                .tracking(0.8)
            VStack(spacing: 10) { content() }
        }
    }

    private func drawerButton(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            POSListRow(title: title, subtitle: subtitle, systemImage: icon, iconTint: tint)
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private var profileCard: some View {
        POSCard {
            HStack(spacing: 14) {
                Text(session.userInitials())
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(POSTheme.primaryDark)
                    .frame(width: 52, height: 52)
                    .background(POSTheme.primary.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.user?.name ?? "Your account")
                        .font(.posDisplay(20))
                    Text(session.user?.email ?? "Signed in")
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
                Spacer()
            }
        }
    }

    private var signOutButton: some View {
        POSActionButton(title: "Sign out", icon: "rectangle.portrait.and.arrow.right", style: .secondary) {
            session.signOut()
        }
    }
}
