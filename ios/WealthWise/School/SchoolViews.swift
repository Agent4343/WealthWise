import SwiftUI

// MARK: - Chapter List View

struct ChapterListView: View {
    @StateObject private var viewModel = SchoolViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var selectedChapter: Chapter?
    @State private var showPaywall = false

    private var tier: SubscriptionTier {
        authManager.currentUser?.subscriptionTier ?? .free
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The School")
                            .font(.largeTitle.bold())
                        Text("7 chapters covering everything school never taught you about Canadian personal finance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Chapters
                    ForEach(viewModel.chapters) { chapter in
                        ChapterRowView(
                            chapter: chapter,
                            isUnlocked: viewModel.isChapterUnlocked(chapter, tier: tier),
                            progress: viewModel.chapterProgress(
                                chapterId: chapter.id,
                                totalLessons: chapter.lessonCount
                            )
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.isChapterUnlocked(chapter, tier: tier) {
                                selectedChapter = chapter
                            } else {
                                showPaywall = true
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("The School")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedChapter) { chapter in
                LessonListView(chapter: chapter, viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(requiredTier: .basic)
            }
        }
    }
}

// MARK: - Chapter Row

struct ChapterRowView: View {
    let chapter: Chapter
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        HStack(spacing: 16) {
            // Chapter emoji / lock
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)

                if isUnlocked {
                    Text(chapter.emoji)
                        .font(.title2)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Ch. \(chapter.id)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !isUnlocked {
                        Label("Basic", systemImage: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Text(chapter.title)
                    .font(.headline)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(chapter.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if isUnlocked && progress > 0 {
                    ProgressView(value: progress)
                        .tint(.blue)
                        .padding(.top, 4)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Lesson List View

struct LessonListView: View {
    let chapter: Chapter
    @ObservedObject var viewModel: SchoolViewModel
    @State private var selectedLesson: Lesson?

    var body: some View {
        List {
            Section {
                ForEach(chapter.lessons) { lesson in
                    HStack {
                        Image(systemName: viewModel.isLessonComplete(chapterId: chapter.id, lessonId: lesson.id)
                            ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(viewModel.isLessonComplete(chapterId: chapter.id, lessonId: lesson.id)
                                ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(lesson.title)
                                .font(.headline)
                            Text("\(lesson.keyPoints.count) key points")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedLesson = lesson }
                }
            } header: {
                Text("\(chapter.lessonCount) lessons")
            }
        }
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson, chapter: chapter, viewModel: viewModel)
        }
    }
}

// MARK: - Lesson Detail View

struct LessonDetailView: View {
    let lesson: Lesson
    let chapter: Chapter
    @ObservedObject var viewModel: SchoolViewModel
    @State private var showQuiz = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Content
                Text(lesson.content)
                    .font(.body)
                    .lineSpacing(6)
                    .padding(.horizontal)

                // Key Points
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Points")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(lesson.keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .padding(.top, 2)
                            Text(point)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Quiz / Complete button
                if let quiz = lesson.quiz {
                    Button(action: { showQuiz = true }) {
                        Label("Take the Quiz", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                } else {
                    Button(action: markComplete) {
                        Label("Mark Complete", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQuiz) {
            if let quiz = lesson.quiz {
                QuizView(quiz: quiz, onComplete: { passed in
                    if passed { markComplete() }
                })
            }
        }
    }

    private func markComplete() {
        viewModel.markLessonComplete(chapterId: chapter.id, lessonId: lesson.id)
        dismiss()
    }
}

// MARK: - Quiz View

struct QuizView: View {
    let quiz: Quiz
    let onComplete: (Bool) -> Void
    @State private var selectedIndex: Int?
    @State private var isAnswered = false
    @Environment(\.dismiss) private var dismiss

    var isCorrect: Bool {
        selectedIndex == quiz.correctIndex
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(quiz.question)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top)

                VStack(spacing: 12) {
                    ForEach(0..<quiz.options.count, id: \.self) { index in
                        QuizOptionButton(
                            text: quiz.options[index],
                            state: optionState(for: index),
                            action: { selectOption(index) }
                        )
                        .disabled(isAnswered)
                    }
                }
                .padding(.horizontal)

                if isAnswered {
                    VStack(spacing: 16) {
                        Text(isCorrect ? "✅ Correct!" : "❌ Not quite")
                            .font(.headline)
                            .foregroundStyle(isCorrect ? .green : .red)

                        Text(quiz.explanation)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { onComplete(isCorrect); dismiss() }) {
                            Text(isCorrect ? "Continue" : "Got it")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isCorrect ? .green : .blue)
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Quick Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") { onComplete(false); dismiss() }
                }
            }
        }
    }

    private func selectOption(_ index: Int) {
        guard !isAnswered else { return }
        selectedIndex = index
        isAnswered = true
    }

    private func optionState(for index: Int) -> QuizOptionState {
        guard isAnswered, let selected = selectedIndex else { return .default }
        if index == quiz.correctIndex { return .correct }
        if index == selected && selected != quiz.correctIndex { return .incorrect }
        return .default
    }
}

enum QuizOptionState { case `default`, correct, incorrect }

struct QuizOptionButton: View {
    let text: String
    let state: QuizOptionState
    let action: () -> Void

    var backgroundColor: Color {
        switch state {
        case .default: return Color(.systemGray6)
        case .correct: return Color.green.opacity(0.15)
        case .incorrect: return Color.red.opacity(0.15)
        }
    }

    var borderColor: Color {
        switch state {
        case .default: return Color.clear
        case .correct: return Color.green
        case .incorrect: return Color.red
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChapterListView()
        .environmentObject(AuthManager.shared)
}
