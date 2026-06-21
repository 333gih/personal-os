import SwiftUI

struct POSDSADailyFocusCard: View {
    let focus: POSDSADailyFocus?
    let onOpenPattern: () -> Void
    let onCoach: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            POSSectionHeader(
                title: "DSA daily program",
                eyebrow: focus.map { "Week \($0.programWeek)/10 · Day \($0.programDay) · \($0.phaseLabel)" } ?? "10-week mastery"
            )

            if let focus {
                POSCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("#\(focus.patternOrder) \(focus.patternTitle)")
                                    .font(.headline)
                                Text("\(focus.dayTypeLabel) · \(focus.targetProblems) problems · \(focus.cumulativeTarget)+ cumulative target")
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.muted)
                            }
                            Spacer()
                            if focus.mockToday {
                                Text("MOCK")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(POSTheme.focus.opacity(0.2))
                                    .foregroundStyle(POSTheme.focus)
                                    .clipShape(Capsule())
                            }
                        }

                        ForEach(focus.tasks.prefix(3), id: \.self) { task in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(POSTheme.primaryDark)
                                Text(task).font(.caption).foregroundStyle(POSTheme.ink)
                            }
                        }

                        if let probs = focus.suggestedProblems, !probs.isEmpty {
                            Text("Suggested: \(probs.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(POSTheme.muted)
                        }

                        HStack(spacing: 10) {
                            Button(action: onOpenPattern) {
                                Label("Pattern theory", systemImage: "book.fill")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(POSPressButtonStyle())
                            Button(action: onCoach) {
                                Label("AI drill", systemImage: "sparkles")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(POSPressButtonStyle())
                        }
                        .foregroundStyle(POSTheme.primaryDark)
                    }
                }
            } else {
                Text("Pull to refresh after migration 022 on server.")
                    .font(.caption)
                    .foregroundStyle(POSTheme.muted)
            }
        }
    }
}

struct POSTodayStudySection: View {
    let plan: POSTodayStudyPlan?
    let isLoading: Bool
    let onOpenBlock: (POSTodayStudyBlock) -> Void
    let onEditSchedule: () -> Void

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                POSSectionHeader(
                    title: "Today's plan",
                    eyebrow: plan.map { "\($0.totalMinutes) min · \($0.isWorkDay ? "Work day" : "Weekend")" } ?? "Commute-optimized"
                )
                Spacer()
                Button(action: onEditSchedule) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(POSTheme.primaryDark)
                }
                .buttonStyle(POSPressButtonStyle())
            }

            if isLoading {
                POSLoadingView(label: "Building schedule…")
            } else if let plan, !plan.blocks.isEmpty {
                ForEach(plan.blocks) { block in
                    blockRow(block)
                }
            } else {
                Text("No blocks today — adjust your work schedule in settings.")
                    .font(.caption)
                    .foregroundStyle(POSTheme.muted)
            }
        }
    }

    private func blockRow(_ block: POSTodayStudyBlock) -> some View {
        let isPast = block.startAt < Date()
        return Button { onOpenBlock(block) } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text(timeFormatter.string(from: block.startAt))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(POSTheme.primaryDark)
                    Text("\(block.durationMinutes)m")
                        .font(.caption2)
                        .foregroundStyle(POSTheme.muted)
                }
                .frame(width: 52)

                Rectangle()
                    .fill(trackColor(block.track).opacity(0.35))
                    .frame(width: 3)
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(block.track.uppercased(), systemImage: block.track == "dsa" ? "function" : "text.book.closed")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(trackColor(block.track))
                        Spacer()
                        if isPast {
                            Text("Done?").font(.caption2).foregroundStyle(POSTheme.muted)
                        } else {
                            Text(modeLabel(block.mode)).font(.caption2).foregroundStyle(POSTheme.muted)
                        }
                    }
                    Text(block.title).font(.subheadline.weight(.semibold)).foregroundStyle(POSTheme.ink)
                    Text(block.subtitle).font(.caption).foregroundStyle(POSTheme.muted).lineLimit(2)
                    if let tip = block.commuteTip {
                        Text(tip)
                            .font(.caption2)
                            .foregroundStyle(POSTheme.primaryDark.opacity(0.85))
                            .padding(.top, 2)
                    }
                }
            }
            .padding(12)
            .background(POSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: POSTheme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: POSTheme.cardRadius).stroke(POSTheme.border, lineWidth: 1))
            .opacity(isPast ? 0.72 : 1)
        }
        .buttonStyle(POSPressButtonStyle())
    }

    private func trackColor(_ track: String) -> Color {
        track == "dsa" ? POSTheme.primaryDark : POSTheme.focus
    }

    private func modeLabel(_ mode: String) -> String {
        switch mode {
        case "flash": return "Metro flash"
        case "vocab": return "Vocab sprint"
        case "deep": return "Deep block"
        default: return mode.capitalized
        }
    }
}

struct POSLearningScheduleSettingsView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var schedule = POSLearningSchedule.default
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            POSScreen {
                Form {
                    Section("Work hours") {
                        Stepper("Start: \(schedule.workStartHour):00", value: $schedule.workStartHour, in: 5 ... 12)
                        Stepper("End: \(schedule.workEndHour):00", value: $schedule.workEndHour, in: 14 ... 22)
                    }
                    Section("Commute (metro / bus)") {
                        TextField("Morning", text: $schedule.morningCommuteTime)
                        TextField("Evening", text: $schedule.eveningCommuteTime)
                        Stepper("DSA on commute: \(schedule.dsaCommuteMinutes) min", value: $schedule.dsaCommuteMinutes, in: 5 ... 60)
                        Stepper("English vocab: \(schedule.englishCommuteMinutes) min", value: $schedule.englishCommuteMinutes, in: 5 ... 45)
                    }
                    Section("TOEIC hardcore") {
                        TextField("Evening session", text: $schedule.toeicSessionTime)
                        Stepper("Daily deep study: \(schedule.toeicDailyMinutes) min", value: $schedule.toeicDailyMinutes, in: 15 ... 180)
                    }
                    Section("Notifications") {
                        Toggle("Push + local reminders", isOn: $schedule.pushEnabled)
                    }
                    if let errorMessage {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Study schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            schedule = try await session.api.fetchLearningSchedule()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            schedule = try await session.api.saveLearningSchedule(schedule)
            await POSLocalNotificationScheduler.shared.syncFromServer(session: session)
            POSHaptics.light()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct POSNotificationLogView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var items: [POSNotificationLogItem] = []
    @State private var isLoading = true

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }

    var body: some View {
        NavigationStack {
            POSScreen {
                Group {
                    if isLoading {
                        POSLoadingView(label: "Loading log…")
                    } else if items.isEmpty {
                        POSEmptyState(
                            systemImage: "bell.slash",
                            title: "No notifications yet",
                            message: "Study reminders and AI coach alerts will appear here.",
                            actionTitle: "Close",
                            action: { dismiss() }
                        )
                    } else {
                        List(items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.title).font(.subheadline.weight(.semibold))
                                    Spacer()
                                    statusBadge(item.status)
                                }
                                Text(item.body).font(.caption).foregroundStyle(POSTheme.muted)
                                Text(dateFormatter.string(from: item.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(POSTheme.muted)
                            }
                            .listRowBackground(POSTheme.card)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Notification log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "sent": return .green
        case "failed": return .red
        case "skipped": return .orange
        default: return POSTheme.muted
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await session.api.fetchNotificationLog()
        } catch {
            items = []
        }
    }
}
