import SwiftUI
import UIKit

enum POSHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct POSPressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct POSNavigationActions {
    let onOpen: WebOpenHandler
    let onSwitchTab: (POSTab) -> Void
    let onLegacyScreen: (WebSheetRoute) -> Void
    var onOpenCV: (() -> Void)?
    var onOpenJobScout: (() -> Void)?
    var onOpenWorkImport: (() -> Void)?
    var onOpenWorkAdd: (() -> Void)?
    var onOpenWorkHub: (() -> Void)?
    var onOpenStartup: (() -> Void)?
    var onOpenStartupHub: (() -> Void)?
    var onOpenStartupAdd: (() -> Void)?
    var onOpenLearningHub: (() -> Void)?
    var onOpenLearningAdd: ((POSLearningTrack) -> Void)?
    var onOpenLearningCoach: ((POSLearningTrack, String?, String) -> Void)?
    var onOpenLearningLesson: ((String, String) -> Void)?
    var onOpenInterviewPrep: (() -> Void)?

    func captureNote() {
        POSHaptics.medium()
        onOpen(.path("/inbox", title: "Capture"))
    }

    func openSettings() {
        POSHaptics.light()
        onSwitchTab(.more)
    }

    func openCV() {
        POSHaptics.light()
        onOpenCV?()
    }

    func openJobScout() {
        POSHaptics.light()
        onOpenJobScout?()
    }

    func openWorkImport() {
        POSHaptics.light()
        onOpenWorkImport?()
    }

    func openWorkAdd() {
        POSHaptics.light()
        onOpenWorkAdd?()
    }

    func openWorkHub() {
        POSHaptics.light()
        onOpenWorkHub?()
    }

    func openStartup() {
        POSHaptics.light()
        onOpenStartup?()
    }

    func openStartupHub() {
        POSHaptics.light()
        onOpenStartupHub?()
    }

    func openStartupAdd() {
        POSHaptics.light()
        onOpenStartupAdd?()
    }

    func openLearningHub() {
        POSHaptics.light()
        onOpenLearningHub?()
    }

    func openLearningAdd(track: POSLearningTrack) {
        POSHaptics.light()
        onOpenLearningAdd?(track)
    }

    func openLearningCoach(track: POSLearningTrack, entityID: String? = nil, topic: String = "") {
        POSHaptics.light()
        onOpenLearningCoach?(track, entityID, topic)
    }

    func openLearningLesson(id: String, title: String) {
        POSHaptics.light()
        onOpenLearningLesson?(id, title)
    }

    func openInterviewPrep() {
        POSHaptics.light()
        onOpenInterviewPrep?()
    }

    func openStorySync() {
        POSHaptics.light()
        onLegacyScreen(.path("/entertainment", title: "Reading Log"))
    }
}

struct POSJournalBackground: View {
    var body: some View {
        ZStack {
            POSTheme.background
            LinearGradient(
                colors: [POSTheme.paperHighlight.opacity(0.55), .clear, POSTheme.paperShadow.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { geo in
                Path { path in
                    var y: CGFloat = 88
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width - 20, y: y))
                        y += 30
                    }
                }
                .stroke(POSTheme.paperLine.opacity(0.35), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }
}

struct POSScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            POSJournalBackground()
            content()
        }
    }
}

struct POSJournalDateStamp: View {
    let name: String

    private var todayLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(todayLine)
                .font(.caption.weight(.medium))
                .foregroundStyle(POSTheme.muted)
                .tracking(0.3)
            Text(name)
                .font(.posDisplay(34))
                .foregroundStyle(POSTheme.ink)
            Text("A quiet page for notes, progress, and what comes next.")
                .font(.subheadline)
                .foregroundStyle(POSTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct POSActionButton: View {
    let title: String
    var icon: String?
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary, secondary, ghost
    }

    var body: some View {
        Button(action: {
            POSHaptics.light()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: style == .ghost ? nil : .infinity)
            .padding(.horizontal, style == .ghost ? 0 : 16)
            .padding(.vertical, 12)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(border, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private var background: Color {
        switch style {
        case .primary: return POSTheme.ink
        case .secondary: return POSTheme.card
        case .ghost: return .clear
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: return POSTheme.background
        case .secondary, .ghost: return POSTheme.ink
        }
    }

    private var border: Color {
        style == .secondary ? POSTheme.border : .clear
    }
}

struct POSFloatingCaptureButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(POSTheme.ink)
                .clipShape(Circle())
                .shadow(color: POSTheme.ink.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(POSPressButtonStyle(scale: 0.94))
    }
}
