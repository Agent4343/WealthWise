import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    @ObservedObject var viewModel: SchoolViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(lesson.content) { block in
                    lessonBlockView(block)
                }

                // Mark Complete Button
                if !viewModel.isLessonCompleted(lesson.id) {
                    Button {
                        viewModel.markLessonCompleted(lesson.id)
                    } label: {
                        Label("Mark as Complete", systemImage: "checkmark.circle")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 12)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Lesson Complete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func lessonBlockView(_ block: LessonBlock) -> some View {
        switch block.type {
        case .heading:
            Text(block.text)
                .font(.title2.bold())
                .padding(.top, 8)

        case .paragraph:
            Text(block.text)
                .font(.body)
                .lineSpacing(4)

        case .statistic:
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)

                if let highlight = block.highlightText {
                    VStack(alignment: .leading) {
                        Text(highlight)
                            .font(.title.bold())
                            .foregroundStyle(.blue)
                        Text(block.text.replacingOccurrences(of: highlight, with: "").trimmingCharacters(in: .whitespaces))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(block.text)
                        .font(.subheadline.bold())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .callout:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(block.text)
                    .font(.subheadline)
                    .lineSpacing(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .example:
            VStack(alignment: .leading, spacing: 8) {
                Label("Example", systemImage: "pencil.and.outline")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                Text(block.text)
                    .font(.subheadline)
                    .lineSpacing(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .keyTakeaway:
            VStack(alignment: .leading, spacing: 8) {
                Label("Key Takeaway", systemImage: "key.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Text(block.text)
                    .font(.subheadline.weight(.medium))
                    .lineSpacing(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
