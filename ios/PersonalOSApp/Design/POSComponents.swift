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
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: POSTheme.cardRadius, style: .continuous)
                    .stroke(POSTheme.border.opacity(0.6), lineWidth: 1)
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
                    Text(eyebrow.uppercased())
                        .font(.posLabel(10))
                        .tracking(1.2)
                        .foregroundStyle(POSTheme.muted)
                }
                Text(title)
                    .font(.posDisplay(20))
                    .foregroundStyle(POSTheme.foreground)
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle.uppercased(), action: action)
                    .font(.posLabel(10))
                    .tracking(0.8)
                    .foregroundStyle(POSTheme.primaryDark)
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

    var body: some View {
        POSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label.uppercased())
                        .font(.posLabel(10))
                        .tracking(1)
                        .foregroundStyle(POSTheme.muted)
                    Spacer()
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(accent)
                    }
                }
                Text(value)
                    .font(.posDisplay(26))
                    .foregroundStyle(POSTheme.foreground)
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
                    .fill(POSTheme.border.opacity(0.5))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .foregroundStyle(iconTint)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let badge {
                    Text(badge.uppercased())
                        .font(.posLabel(9))
                        .foregroundStyle(POSTheme.muted)
                }
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(POSTheme.foreground)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(POSTheme.muted)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(POSTheme.muted)
        }
        .padding(14)
        .background(POSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(POSTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
}

struct POSEmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(POSTheme.muted)
                .frame(width: 56, height: 56)
                .background(POSTheme.border.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(title)
                .font(.posDisplay(18))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(POSTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct POSLoadingView: View {
    var label = "Loading…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(POSTheme.primary)
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
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? POSTheme.primaryDark : POSTheme.card)
                .foregroundStyle(isSelected ? .white : POSTheme.foreground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(POSTheme.border, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
