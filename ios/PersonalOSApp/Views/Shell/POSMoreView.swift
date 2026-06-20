import SwiftUI

struct POSMoreMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let path: String
    let sheetTitle: String
}

struct POSMoreView: View {
    @EnvironmentObject private var session: SessionManager
    let nav: POSNavigationActions

    private let sections: [(title: String, items: [POSMoreMenuItem])] = [
        ("Capture", [
            POSMoreMenuItem(
                title: "Inbox",
                subtitle: "Quick notes, links, and captures",
                systemImage: "tray.full",
                tint: POSTheme.primaryDark,
                path: "/inbox",
                sheetTitle: "Inbox"
            ),
        ]),
        ("Explore", [
            POSMoreMenuItem(
                title: "CV Transfer",
                subtitle: "Ideal resume, AI edit, PDF export & share",
                systemImage: "doc.richtext.fill",
                tint: POSTheme.primaryDark,
                path: "/cv",
                sheetTitle: "CV"
            ),
            POSMoreMenuItem(
                title: "Job Scout",
                subtitle: "Daily skill-matched jobs from Remotive & GitHub",
                systemImage: "briefcase.fill",
                tint: POSTheme.focus,
                path: "/jobs",
                sheetTitle: "Jobs"
            ),
            POSMoreMenuItem(
                title: "Startup",
                subtitle: "Ideas, pain points, and experiments",
                systemImage: "rocket.fill",
                tint: POSTheme.focus,
                path: "/startup",
                sheetTitle: "Startup"
            ),
            POSMoreMenuItem(
                title: "Entertainment",
                subtitle: "Reading log & story sync",
                systemImage: "gamecontroller.fill",
                tint: Color(red: 0.45, green: 0.35, blue: 0.72),
                path: "/entertainment",
                sheetTitle: "Reading Log"
            ),
        ]),
        ("Account", [
            POSMoreMenuItem(
                title: "Settings",
                subtitle: "Profile, Safari extension, preferences",
                systemImage: "gearshape.fill",
                tint: POSTheme.muted,
                path: "/settings",
                sheetTitle: "Settings"
            ),
        ]),
    ]

    var body: some View {
        POSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileCard
                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title.uppercased())
                                .font(.posCaps())
                                .foregroundStyle(POSTheme.muted)
                                .tracking(0.8)
                            VStack(spacing: 10) {
                                ForEach(section.items) { item in
                                    Button {
                                        if item.path == "/cv" {
                                            nav.openCV()
                                        } else if item.path == "/jobs" {
                                            nav.openJobScout()
                                        } else {
                                            nav.onOpen(.path(item.path, title: item.sheetTitle))
                                        }
                                    } label: {
                                        POSListRow(
                                            title: item.title,
                                            subtitle: item.subtitle,
                                            systemImage: item.systemImage,
                                            iconTint: item.tint
                                        )
                                    }
                                    .buttonStyle(POSPressButtonStyle())
                                }
                            }
                        }
                    }
                    signOutButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
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
