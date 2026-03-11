import Foundation

// MARK: - Chapter

struct Chapter: Codable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let emoji: String
    let lessons: [Lesson]

    var lessonCount: Int { lessons.count }
}

// MARK: - Lesson

struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let keyPoints: [String]
    let quiz: Quiz?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case keyPoints = "key_points"
        case quiz
    }
}

// MARK: - Quiz

struct Quiz: Codable {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case question
        case options
        case correctIndex = "correct_index"
        case explanation
    }
}

// MARK: - Learning Progress

struct ChapterProgress: Codable {
    let chapterId: Int
    var completedLessonIds: Set<String>
    var quizScores: [String: Bool]   // lessonId → passed

    var isComplete: Bool {
        // Checked against known chapter lesson counts externally
        false
    }
}
