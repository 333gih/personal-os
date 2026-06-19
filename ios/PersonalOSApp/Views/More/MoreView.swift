import SwiftUI
import UIKit

struct MoreView: View {
    @EnvironmentObject private var session: SessionManager
    let onOpen: WebOpenHandler
    let onSignOut: () -> Void
    var onOpenStartup: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                accountSection
                safariExtensionCard
                preferencesSection
                Button("Sign out", role: .destructive) { onSignOut() }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var accountSection: some View {
        VStack(spacing: 8) {
            POSListRow(
                title: session.user?.name ?? "Your account",
                subtitle: session.user?.email ?? "Personal OS",
                systemImage: "person.crop.circle.fill",
                iconTint: POSTheme.primary
            )
            POSListRow(title: "Password & Security", subtitle: "Biometrics and 2FA", systemImage: "key.fill")
            Button { onOpen(.path("/settings", title: "Settings")) } label: {
                POSListRow(title: "Data & Privacy", subtitle: "Manage sync preferences", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
            Button { onOpenStartup?() } label: {
                POSListRow(title: "Startup Ecosystem", subtitle: "Portfolio & schedule", systemImage: "rocket.fill", iconTint: POSTheme.primaryDark)
            }
            .buttonStyle(.plain)
        }
    }

    private var safariExtensionCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [.orange, POSTheme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 140)
                VStack(alignment: .leading, spacing: 8) {
                    Text("FEATURED")
                        .font(.posLabel(9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("Safari Extension\nStory Tracker")
                        .font(.posDisplay(22))
                        .foregroundStyle(.white)
                }
                .padding(20)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Track reading progress and save inspirations from Safari.")
                    .font(.subheadline)
                    .foregroundStyle(POSTheme.muted)
                ForEach(Array(safariSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .frame(width: 22, height: 22)
                            .background(POSTheme.border.opacity(0.5))
                            .clipShape(Circle())
                        Text(step).font(.caption).foregroundStyle(POSTheme.muted)
                    }
                }
                Button("Connect in Safari") { openSafariConnect() }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(POSTheme.primaryDark)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Button("View synced progress") { onOpen(.path("/entertainment", title: "Entertainment")) }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(POSTheme.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GENERAL PREFERENCES")
                .font(.posLabel(10))
                .foregroundStyle(POSTheme.muted)
                .padding(.top, 8)
            Button { onOpen(.path("/settings", title: "Settings")) } label: {
                POSListRow(title: "Appearance", subtitle: "Auto", systemImage: "paintpalette.fill")
            }
            .buttonStyle(.plain)
            Button { onOpen(.path("/inbox", title: "Notifications")) } label: {
                POSListRow(title: "Notifications", subtitle: "Reminders", systemImage: "bell.fill")
            }
            .buttonStyle(.plain)
            Button { onOpen(.path("/dashboard", title: "About")) } label: {
                POSListRow(title: "About Personal OS", subtitle: "Version 1.4", systemImage: "info.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private let safariSteps = [
        "Open Safari on this device.",
        "Tap the AA or puzzle icon in the search bar.",
        "Select Manage Extensions.",
        "Toggle Personal OS / Story Tracker to enable.",
    ]

    private func openSafariConnect() {
        let url = PersonalOSAppConfig.frontendPath("/extension/connect")
        UIApplication.shared.open(url)
    }
}
