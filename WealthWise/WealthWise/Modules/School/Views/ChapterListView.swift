import SwiftUI

struct ChapterListView: View {
    @StateObject private var viewModel = SchoolViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress Header
                    progressHeader

                    // Chapters
                    ForEach(viewModel.chapters) { chapter in
                        let accessible = viewModel.isChapterAccessible(
                            chapter,
                            userTier: subscriptionVM.currentTier
                        )

                        if accessible {
                            NavigationLink(value: chapter) {
                                ChapterCard(
                                    chapter: chapter,
                                    isLocked: false,
                                    quizScore: viewModel.quizScore(for: chapter.id),
                                    completedLessons: chapter.lessons.filter {
                                        viewModel.isLessonCompleted($0.id)
                                    }.count,
                                    totalLessons: chapter.lessons.count
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            ChapterCard(
                                chapter: chapter,
                                isLocked: true,
                                quizScore: nil,
                                completedLessons: 0,
                                totalLessons: chapter.lessons.count
                            )
                            .onTapGesture {
                                subscriptionVM.showPaywall = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("The School")
            .navigationDestination(for: Chapter.self) { chapter in
                LessonListView(chapter: chapter, viewModel: viewModel)
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.completedCount)/\(viewModel.totalLessons) lessons")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: viewModel.progressPercent)
                .tint(.green)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ChapterCard: View {
    let chapter: Chapter
    let isLocked: Bool
    let quizScore: Int?
    let completedLessons: Int
    let totalLessons: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isLocked ? "lock.fill" : chapter.iconName)
                .font(.title2)
                .foregroundStyle(isLocked ? .secondary : .accent)
                .frame(width: 44, height: 44)
                .background(isLocked ? Color.gray.opacity(0.1) : Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text("Chapter \(chapter.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(chapter.title)
                    .font(.headline)
                    .foregroundStyle(isLocked ? .secondary : .primary)

                Text(chapter.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !isLocked {
                    HStack(spacing: 12) {
                        Label("\(completedLessons)/\(totalLessons)", systemImage: "checkmark.circle")
                            .font(.caption2)

                        if let score = quizScore {
                            Label("Quiz: \(score)%", systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isLocked ? 0.7 : 1)
    }
}

extension Chapter: Hashable {
    static func == (lhs: Chapter, rhs: Chapter) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
