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

enum POSLearningTrack: String, CaseIterable, Identifiable {
    case dsa, english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dsa: return "DSA & Algorithms"
        case .english: return "English"
        }
    }

    var icon: String {
        switch self {
        case .dsa: return "function"
        case .english: return "text.book.closed"
        }
    }
}
