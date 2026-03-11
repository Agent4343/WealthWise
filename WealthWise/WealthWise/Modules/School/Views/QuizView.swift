import SwiftUI

struct QuizView: View {
    let chapter: Chapter
    @ObservedObject var viewModel: SchoolViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentQuestion = 0
    @State private var selectedAnswer: Int?
    @State private var showExplanation = false
    @State private var correctCount = 0
    @State private var isFinished = false

    private var questions: [QuizQuestion] {
        chapter.quiz.questions
    }

    var body: some View {
        if isFinished {
            quizResults
        } else {
            questionView
        }
    }

    private var questionView: some View {
        VStack(spacing: 24) {
            // Progress
            HStack {
                Text("Question \(currentQuestion + 1) of \(questions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(correctCount) correct")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            .padding(.horizontal)

            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .padding(.horizontal)

            let question = questions[currentQuestion]

            // Question
            Text(question.question)
                .font(.title3.bold())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Options
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        guard selectedAnswer == nil else { return }
                        selectedAnswer = index
                        showExplanation = true
                        if index == question.correctIndex {
                            correctCount += 1
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer()

                            if showExplanation {
                                if index == question.correctIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if index == selectedAnswer {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding()
                        .background(optionBackground(index: index, correctIndex: question.correctIndex))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedAnswer != nil)
                }
            }
            .padding(.horizontal)

            // Explanation
            if showExplanation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explanation")
                        .font(.caption.bold())
                    Text(question.explanation)
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Button {
                    if currentQuestion < questions.count - 1 {
                        currentQuestion += 1
                        selectedAnswer = nil
                        showExplanation = false
                    } else {
                        let score = Int(Double(correctCount) / Double(questions.count) * 100)
                        viewModel.saveQuizScore(chapterId: chapter.id, score: score)
                        isFinished = true
                    }
                } label: {
                    Text(currentQuestion < questions.count - 1 ? "Next Question" : "See Results")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Chapter \(chapter.id) Quiz")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var quizResults: some View {
        VStack(spacing: 24) {
            Spacer()

            let score = Int(Double(correctCount) / Double(questions.count) * 100)

            Image(systemName: score >= 70 ? "star.fill" : "arrow.counterclockwise")
                .font(.system(size: 64))
                .foregroundStyle(score >= 70 ? .yellow : .orange)

            Text(score >= 70 ? "Great Job!" : "Keep Learning!")
                .font(.title.bold())

            Text("\(correctCount) out of \(questions.count) correct (\(score)%)")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func optionBackground(index: Int, correctIndex: Int) -> Color {
        guard showExplanation else { return Color(.secondarySystemBackground) }

        if index == correctIndex {
            return Color.green.opacity(0.15)
        } else if index == selectedAnswer {
            return Color.red.opacity(0.15)
        }
        return Color(.secondarySystemBackground)
    }
}
