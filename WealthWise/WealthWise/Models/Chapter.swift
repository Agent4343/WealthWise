import Foundation

struct Chapter: Codable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let iconName: String
    let lessons: [Lesson]
    let quiz: Quiz
    let requiredTier: SubscriptionTier

    var isFreeTier: Bool {
        requiredTier == .free
    }
}

struct Lesson: Codable, Identifiable {
    let id: Int
    let title: String
    let content: [LessonBlock]
}

struct LessonBlock: Codable, Identifiable {
    let id: Int
    let type: BlockType
    let text: String
    let highlightText: String?

    enum BlockType: String, Codable {
        case heading
        case paragraph
        case statistic
        case callout
        case example
        case keyTakeaway = "key_takeaway"
    }
}

struct Quiz: Codable {
    let questions: [QuizQuestion]
}

struct QuizQuestion: Codable, Identifiable {
    let id: Int
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case id, question, options
        case correctIndex = "correct_index"
        case explanation
    }
}
