import SwiftUI

struct LessonListView: View {
    let chapter: Chapter
    @ObservedObject var viewModel: SchoolViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(chapter.lessons) { lesson in
                    NavigationLink {
                        LessonView(lesson: lesson, viewModel: viewModel)
                    } label: {
                        HStack {
                            Image(systemName: viewModel.isLessonCompleted(lesson.id)
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.isLessonCompleted(lesson.id) ? .green : .secondary)

                            Text(lesson.title)
                                .font(.body)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }

                // Quiz section
                NavigationLink {
                    QuizView(chapter: chapter, viewModel: viewModel)
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.orange)

                        Text("Chapter Quiz")
                            .font(.body.bold())

                        Spacer()

                        if let score = viewModel.quizScore(for: chapter.id) {
                            Text("\(score)%")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Ch. \(chapter.id): \(chapter.title)")
    }
}
