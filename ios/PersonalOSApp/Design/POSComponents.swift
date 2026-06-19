import SwiftUI

struct POSCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous))
            .shadow(color: POSTheme.paperShadow.opacity(0.08), radius: 10, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous)
                    .stroke(POSTheme.border.opacity(0.75), lineWidth: 1)
            )
    }
}

struct POSSectionHeader: View {
    let title: String
    var eyebrow: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(POSTheme.muted)
                }
                Text(title)
                    .font(.posDisplay(20))
                    .foregroundStyle(POSTheme.ink)
            }
            Spacer()
            if let actionTitle, let action {
                Button(action: {
                    POSHaptics.selection()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                }
                .buttonStyle(POSPressButtonStyle())
            }
        }
    }
}

struct POSMetricCard: View {
    let label: String
    let value: String
    var hint: String?
    var systemImage: String?
    var accent: Color = POSTheme.muted
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: {
                    POSHaptics.light()
                    action()
                }) {
                    cardBody
                }
                .buttonStyle(POSPressButtonStyle())
            } else {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(POSTheme.muted)
                    Spacer()
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(accent)
                    }
                }
                Text(value)
                    .font(.posDisplay(26))
                    .foregroundStyle(POSTheme.ink)
                if let hint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                }
            }
        }
    }
}

struct POSListRow: View {
    let title: String
    var subtitle: String?
    var badge: String?
    var systemImage: String = "circle"
    var iconTint: Color = POSTheme.muted

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(POSTheme.border.opacity(0.45))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .foregroundStyle(iconTint)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(POSTheme.muted)
                }
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(POSTheme.ink)
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(POSTheme.muted.opacity(0.8))
        }
        .padding(14)
        .background(POSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(POSTheme.border.opacity(0.65), lineWidth: 1)
        )
    }
}

struct POSEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(POSTheme.muted)
                .frame(width: 52, height: 52)
                .background(POSTheme.border.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(title)
                .font(.posDisplay(18))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(POSTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            if let actionTitle, let action {
                POSActionButton(title: actionTitle, style: .secondary, action: action)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

struct POSLoadingView: View {
    var label = "Loading…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(POSTheme.primaryDark)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(POSTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct POSChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            POSHaptics.selection()
            action()
        }) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? POSTheme.ink : POSTheme.card)
                .foregroundStyle(isSelected ? POSTheme.background : POSTheme.ink)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(POSTheme.border, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(POSPressButtonStyle())
    }
}

struct POSNoteDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(POSTheme.border).frame(height: 1)
            Image(systemName: "bookmark.fill")
                .font(.caption2)
                .foregroundStyle(POSTheme.primary.opacity(0.7))
            Rectangle().fill(POSTheme.border).frame(height: 1)
        }
    }
}
