import Foundation
import SwiftUI

@MainActor
final class SchoolViewModel: ObservableObject {
    @Published var chapters: [Chapter] = []
    @Published var completedLessons: Set<Int> = []
    @Published var quizScores: [Int: Int] = [:] // chapterId: score

    private let completedLessonsKey = "completedLessons"
    private let quizScoresKey = "quizScores"

    init() {
        loadChapters()
        loadProgress()
    }

    var totalLessons: Int {
        chapters.flatMap(\.lessons).count
    }

    var completedCount: Int {
        completedLessons.count
    }

    var progressPercent: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedCount) / Double(totalLessons)
    }

    func isChapterAccessible(_ chapter: Chapter, userTier: SubscriptionTier) -> Bool {
        return userTier >= chapter.requiredTier
    }

    func isLessonCompleted(_ lessonId: Int) -> Bool {
        completedLessons.contains(lessonId)
    }

    func markLessonCompleted(_ lessonId: Int) {
        completedLessons.insert(lessonId)
        saveProgress()
    }

    func saveQuizScore(chapterId: Int, score: Int) {
        quizScores[chapterId] = score
        saveProgress()
    }

    func quizScore(for chapterId: Int) -> Int? {
        quizScores[chapterId]
    }

    private func loadChapters() {
        guard let url = Bundle.main.url(forResource: "chapters", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            // Fallback: try loading from module bundle
            loadChaptersFromModuleBundle()
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let decoded = try? decoder.decode([Chapter].self, from: data) {
            chapters = decoded
        }
    }

    private func loadChaptersFromModuleBundle() {
        // For development: load from the School/Data directory
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let url = Bundle.main.url(forResource: "chapters", withExtension: "json", subdirectory: "Data"),
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([Chapter].self, from: data) {
            chapters = decoded
        }
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: completedLessonsKey),
           let lessons = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            completedLessons = lessons
        }

        if let data = UserDefaults.standard.data(forKey: quizScoresKey),
           let scores = try? JSONDecoder().decode([Int: Int].self, from: data) {
            quizScores = scores
        }
    }

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(completedLessons) {
            UserDefaults.standard.set(data, forKey: completedLessonsKey)
        }
        if let data = try? JSONEncoder().encode(quizScores) {
            UserDefaults.standard.set(data, forKey: quizScoresKey)
        }
    }
}
