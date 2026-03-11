import Foundation

// MARK: - School ViewModel

@MainActor
final class SchoolViewModel: ObservableObject {
    @Published var chapters: [Chapter] = []
    @Published var progressMap: [Int: Set<String>] = [:]  // chapterId → completedLessonIds
    @Published var isLoading: Bool = false

    private let progressKey = "wealthwise_chapter_progress"

    init() {
        loadChapters()
        loadProgress()
    }

    // MARK: - Data Loading

    private func loadChapters() {
        guard let url = Bundle.main.url(forResource: "chapters", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            chapters = try JSONDecoder().decode([Chapter].self, from: data)
        } catch {
            // Fallback to empty — chapters bundled in app
        }
    }

    // MARK: - Progress

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([Int: [String]].self, from: data) else {
            return
        }
        progressMap = decoded.mapValues { Set($0) }
    }

    private func saveProgress() {
        let saveable = progressMap.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(saveable) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    func markLessonComplete(chapterId: Int, lessonId: String) {
        if progressMap[chapterId] == nil {
            progressMap[chapterId] = []
        }
        progressMap[chapterId]?.insert(lessonId)
        saveProgress()
    }

    func isLessonComplete(chapterId: Int, lessonId: String) -> Bool {
        progressMap[chapterId]?.contains(lessonId) ?? false
    }

    func chapterProgress(chapterId: Int, totalLessons: Int) -> Double {
        let completed = progressMap[chapterId]?.count ?? 0
        return totalLessons > 0 ? Double(completed) / Double(totalLessons) : 0
    }

    // MARK: - Tier Access

    func isChapterUnlocked(_ chapter: Chapter, tier: SubscriptionTier) -> Bool {
        // Chapters 1-3 are free; 4-7 require Basic or above
        chapter.id <= 3 || tier == .basic || tier == .premium
    }
}
