import Foundation

struct POSLearningAddResult: Decodable {
    let entityID: String
    let type: String
    let title: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case type, title, content
    }
}

struct POSLearningCoachResult: Decodable {
    let summary: String
    let practiceQuestions: [String]
    let tips: [String]
    let nextSteps: [String]

    enum CodingKeys: String, CodingKey {
        case summary
        case practiceQuestions = "practice_questions"
        case tips
        case nextSteps = "next_steps"
    }
}

struct POSInterviewDrillResult: Decodable {
    let warmupQuestions: [String]
    let deepQuestions: [String]
    let modelAnswersOutline: [String]
    let followUpProbes: [String]
    let studyLinks: [String]

    enum CodingKeys: String, CodingKey {
        case warmupQuestions = "warmup_questions"
        case deepQuestions = "deep_questions"
        case modelAnswersOutline = "model_answers_outline"
        case followUpProbes = "follow_up_probes"
        case studyLinks = "study_links"
    }
}

struct POSLearningSchedule: Codable {
    var workStartHour: Int
    var workEndHour: Int
    var workDays: [Int]
    var commuteMinutes: Int
    var morningCommuteTime: String
    var eveningCommuteTime: String
    var toeicSessionTime: String
    var dsaCommuteMinutes: Int
    var englishCommuteMinutes: Int
    var toeicDailyMinutes: Int
    var timezone: String
    var pushEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case workStartHour = "work_start_hour"
        case workEndHour = "work_end_hour"
        case workDays = "work_days"
        case commuteMinutes = "commute_minutes"
        case morningCommuteTime = "morning_commute_time"
        case eveningCommuteTime = "evening_commute_time"
        case toeicSessionTime = "toeic_session_time"
        case dsaCommuteMinutes = "dsa_commute_minutes"
        case englishCommuteMinutes = "english_commute_minutes"
        case toeicDailyMinutes = "toeic_daily_minutes"
        case timezone
        case pushEnabled = "push_enabled"
    }

    static let `default` = POSLearningSchedule(
        workStartHour: 8,
        workEndHour: 17,
        workDays: [1, 2, 3, 4, 5],
        commuteMinutes: 40,
        morningCommuteTime: "07:15",
        eveningCommuteTime: "17:30",
        toeicSessionTime: "20:00",
        dsaCommuteMinutes: 25,
        englishCommuteMinutes: 20,
        toeicDailyMinutes: 60,
        timezone: "Asia/Ho_Chi_Minh",
        pushEnabled: true
    )
}

struct POSTodayStudyBlock: Identifiable, Decodable {
    let id: String
    let kind: String
    let track: String
    let title: String
    let subtitle: String
    let startAt: Date
    let durationMinutes: Int
    let mode: String
    let entityID: String?
    let commuteTip: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, track, title, subtitle, mode
        case startAt = "start_at"
        case durationMinutes = "duration_minutes"
        case entityID = "entity_id"
        case commuteTip = "commute_tip"
    }
}

struct POSTodayStudyPlan: Decodable {
    let date: String
    let timezone: String
    let isWorkDay: Bool
    let blocks: [POSTodayStudyBlock]
    let totalMinutes: Int
    let dsa: POSDSADailyFocus?

    enum CodingKeys: String, CodingKey {
        case date, timezone, blocks, dsa
        case isWorkDay = "is_work_day"
        case totalMinutes = "total_minutes"
    }
}

struct POSDSADailyFocus: Decodable {
    let programWeek: Int
    let programDay: Int
    let weekday: Int
    let phase: String
    let dayType: String
    let patternOrder: Int
    let patternTitle: String
    let patternEntityID: String
    let tasks: [String]
    let targetProblems: Int
    let cumulativeTarget: Int
    let suggestedProblems: [String]?
    let mockToday: Bool

    enum CodingKeys: String, CodingKey {
        case weekday, phase, tasks
        case programWeek = "program_week"
        case programDay = "program_day"
        case dayType = "day_type"
        case patternOrder = "pattern_order"
        case patternTitle = "pattern_title"
        case patternEntityID = "pattern_entity_id"
        case targetProblems = "target_problems"
        case cumulativeTarget = "cumulative_target"
        case suggestedProblems = "suggested_problems"
        case mockToday = "mock_today"
    }

    var phaseLabel: String {
        switch phase {
        case "foundation": return "Foundation"
        case "core": return "Core patterns"
        case "advanced": return "Advanced"
        default: return "Mock mastery"
        }
    }

    var dayTypeLabel: String {
        switch dayType {
        case "learn": return "Learn"
        case "practice": return "Practice"
        case "review": return "Review"
        case "mock", "weekend_mock", "mock_interview": return "Mock"
        case "timed_pair": return "Timed pair"
        case "morning_evening": return "Split session"
        default: return "Study"
        }
    }
}

struct POSStudyJob: Decodable {
    let id: String
    let kind: String
    let status: String
    let result: POSLearningCoachResult?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, status, result
        case errorMessage = "error_message"
    }
}

struct POSNotificationLogItem: Identifiable, Decodable {
    let id: String
    let channel: String
    let title: String
    let body: String
    let status: String
    let createdAt: Date
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, channel, title, body, status
        case createdAt = "created_at"
        case errorMessage = "error_message"
    }
}

struct POSNotificationLogResponse: Decodable {
    let items: [POSNotificationLogItem]
}

struct POSLearningLesson: Decodable {
    let entityID: String
    let title: String
    let content: String
    let type: String
    let track: String
    let phase: String?
    let weeks: String?
    let patternOrder: Int
    let whenToUse: String?
    let recognitionSignals: [String]
    let practiceStrategy: String?
    let codeTemplate: String?
    let problems: [String]
    let benchmarks: POSDSABenchmarks?
    let modules: [POSLessonModule]?
    let practiceModes: [POSPracticeMode]
    let curriculumWeek: Int

    enum CodingKeys: String, CodingKey {
        case title, content, type, track, phase, weeks, problems, modules, benchmarks
        case entityID = "entity_id"
        case patternOrder = "pattern_order"
        case whenToUse = "when_to_use"
        case recognitionSignals = "recognition_signals"
        case practiceStrategy = "practice_strategy"
        case codeTemplate = "code_template"
        case practiceModes = "practice_modes"
        case curriculumWeek = "curriculum_week"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entityID = try c.decode(String.self, forKey: .entityID)
        title = try c.decode(String.self, forKey: .title)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "learning_topic"
        track = try c.decodeIfPresent(String.self, forKey: .track) ?? "dsa"
        phase = try c.decodeIfPresent(String.self, forKey: .phase)
        weeks = try c.decodeIfPresent(String.self, forKey: .weeks)
        patternOrder = try c.decodeIfPresent(Int.self, forKey: .patternOrder) ?? 0
        whenToUse = try c.decodeIfPresent(String.self, forKey: .whenToUse)
        recognitionSignals = try c.decodeIfPresent([String].self, forKey: .recognitionSignals) ?? []
        practiceStrategy = try c.decodeIfPresent(String.self, forKey: .practiceStrategy)
        codeTemplate = try c.decodeIfPresent(String.self, forKey: .codeTemplate)
        problems = try c.decodeIfPresent([String].self, forKey: .problems) ?? []
        benchmarks = try c.decodeIfPresent(POSDSABenchmarks.self, forKey: .benchmarks)
        modules = try c.decodeIfPresent([POSLessonModule].self, forKey: .modules)
        practiceModes = try c.decodeIfPresent([POSPracticeMode].self, forKey: .practiceModes) ?? []
        curriculumWeek = try c.decodeIfPresent(Int.self, forKey: .curriculumWeek) ?? 0
    }

    init(
        entityID: String,
        title: String,
        content: String,
        type: String,
        track: String,
        phase: String? = nil,
        weeks: String? = nil,
        patternOrder: Int = 0,
        whenToUse: String? = nil,
        recognitionSignals: [String] = [],
        practiceStrategy: String? = nil,
        codeTemplate: String? = nil,
        problems: [String] = [],
        benchmarks: POSDSABenchmarks? = nil,
        modules: [POSLessonModule]? = nil,
        practiceModes: [POSPracticeMode],
        curriculumWeek: Int = 0
    ) {
        self.entityID = entityID
        self.title = title
        self.content = content
        self.type = type
        self.track = track
        self.phase = phase
        self.weeks = weeks
        self.patternOrder = patternOrder
        self.whenToUse = whenToUse
        self.recognitionSignals = recognitionSignals
        self.practiceStrategy = practiceStrategy
        self.codeTemplate = codeTemplate
        self.problems = problems
        self.benchmarks = benchmarks
        self.modules = modules
        self.practiceModes = practiceModes
        self.curriculumWeek = curriculumWeek
    }

    var isCourse: Bool { type.contains("course") }
    var isDSA: Bool { track == "dsa" }

    static func from(entity: POSEntity, modules: [POSLessonModule]? = nil) -> POSLearningLesson {
        let track = entity.metadata?.track ?? (entity.tagList.contains("english") ? "english" : "dsa")
        let order = entity.metadata?.patternOrder ?? 0
        let isCourse = entity.type.contains("course")
        let modes: [POSPracticeMode]
        if isCourse {
            modes = track == "english"
                ? [
                    POSPracticeMode(id: "vocab_flash", title: "Vocab flash", subtitle: "10 words · definition → sentence", durationMinutes: 5, focus: "toeic vocabulary flash", isAsync: false),
                    POSPracticeMode(id: "grammar_drill", title: "Grammar drill", subtitle: "Part 5 traps", durationMinutes: 10, focus: "toeic grammar part 5", isAsync: false),
                ]
                : [
                    POSPracticeMode(id: "roadmap_review", title: "Roadmap check-in", subtitle: "10-week plan", durationMinutes: 5, focus: "10-week DSA roadmap progress", isAsync: false),
                    POSPracticeMode(id: "pattern_pick", title: "Today's pattern", subtitle: "Daily focus", durationMinutes: 25, focus: "daily DSA pattern from program", isAsync: false),
                ]
        } else if track == "english" {
            modes = [
                POSPracticeMode(id: "recall", title: "Active recall", subtitle: "Explain without notes", durationMinutes: 5, focus: "active recall", isAsync: false),
                POSPracticeMode(id: "coach", title: "AI drill", subtitle: "Deep practice", durationMinutes: 15, focus: "deep practice", isAsync: true),
            ]
        } else {
            modes = [
                POSPracticeMode(id: "flash", title: "Metro flash", subtitle: "2 min recall", durationMinutes: 2, focus: "pattern flash recall", isAsync: false),
                POSPracticeMode(id: "easy", title: "Easy warm-up", subtitle: "One easy problem", durationMinutes: 8, focus: "one easy LeetCode", isAsync: false),
                POSPracticeMode(id: "medium", title: "Timed medium", subtitle: "20 min cap", durationMinutes: 20, focus: "one medium LeetCode timed", isAsync: false),
                POSPracticeMode(id: "coach", title: "AI coach deep", subtitle: "Full walkthrough", durationMinutes: 25, focus: "deep coach walkthrough", isAsync: true),
            ]
        }
        return POSLearningLesson(
            entityID: entity.id,
            title: entity.title,
            content: entity.content,
            type: entity.type,
            track: track,
            phase: entity.metadata?.phase,
            weeks: entity.metadata?.week,
            patternOrder: order,
            whenToUse: entity.metadata?.whenToUse,
            recognitionSignals: entity.metadata?.recognitionSignals ?? [],
            practiceStrategy: entity.metadata?.practiceStrategy,
            codeTemplate: entity.metadata?.codeTemplate,
            problems: entity.metadata?.problems ?? [],
            benchmarks: POSDSABenchmarks(
                easyMinutes: entity.metadata?.benchmarkEasyMin ?? 8,
                mediumMinutes: entity.metadata?.benchmarkMediumMin ?? 20,
                hardMinutes: entity.metadata?.benchmarkHardMin ?? 35
            ),
            modules: modules,
            practiceModes: modes,
            curriculumWeek: 0
        )
    }
}

struct POSLessonModule: Identifiable, Decodable {
    let id: String
    let title: String
    let subtitle: String?
    let patternOrder: Int
    let phase: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, phase
        case patternOrder = "pattern_order"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        patternOrder = try c.decodeIfPresent(Int.self, forKey: .patternOrder) ?? 0
        phase = try c.decodeIfPresent(String.self, forKey: .phase)
    }
}

struct POSPracticeMode: Identifiable, Decodable {
    let id: String
    let title: String
    let subtitle: String
    let durationMinutes: Int
    let focus: String
    let isAsync: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, focus
        case durationMinutes = "duration_minutes"
        case isAsync = "async"
    }

    init(id: String, title: String, subtitle: String, durationMinutes: Int, focus: String, isAsync: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.durationMinutes = durationMinutes
        self.focus = focus
        self.isAsync = isAsync
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 5
        focus = try c.decodeIfPresent(String.self, forKey: .focus) ?? ""
        isAsync = try c.decodeIfPresent(Bool.self, forKey: .isAsync) ?? false
    }
}

struct POSDSABenchmarks: Decodable {
    let easyMinutes: Int
    let mediumMinutes: Int
    let hardMinutes: Int

    enum CodingKeys: String, CodingKey {
        case easyMinutes = "easy_minutes"
        case mediumMinutes = "medium_minutes"
        case hardMinutes = "hard_minutes"
    }

    init(easyMinutes: Int, mediumMinutes: Int, hardMinutes: Int) {
        self.easyMinutes = easyMinutes
        self.mediumMinutes = mediumMinutes
        self.hardMinutes = hardMinutes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        easyMinutes = try c.decodeIfPresent(Int.self, forKey: .easyMinutes) ?? 8
        mediumMinutes = try c.decodeIfPresent(Int.self, forKey: .mediumMinutes) ?? 20
        hardMinutes = try c.decodeIfPresent(Int.self, forKey: .hardMinutes) ?? 35
    }
}

enum POSLearningTrack: String, CaseIterable, Identifiable {
    case dsa, english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dsa: return "DSA & Algorithms"
        case .english: return "English / TOEIC"
        }
    }

    var icon: String {
        switch self {
        case .dsa: return "function"
        case .english: return "text.book.closed"
        }
    }
}
