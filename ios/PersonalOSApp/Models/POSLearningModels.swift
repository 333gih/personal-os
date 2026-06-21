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

    enum CodingKeys: String, CodingKey {
        case date, timezone, blocks
        case isWorkDay = "is_work_day"
        case totalMinutes = "total_minutes"
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
