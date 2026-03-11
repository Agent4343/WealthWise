import Foundation

@MainActor
final class BriefViewModel: ObservableObject {
    @Published var briefs: [WeeklyBrief] = []
    @Published var selectedBrief: WeeklyBrief?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true

    private var currentPage = 0
    private let pageSize = 20

    func loadBriefs() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentPage = 0
            let fetched = try await APIService.shared.fetchBriefs(page: 0, limit: pageSize)
            briefs = fetched
            hasMorePages = fetched.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard hasMorePages, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            currentPage += 1
            let fetched = try await APIService.shared.fetchBriefs(page: currentPage, limit: pageSize)
            briefs.append(contentsOf: fetched)
            hasMorePages = fetched.count == pageSize
        } catch {
            currentPage -= 1
            errorMessage = error.localizedDescription
        }
    }

    func loadBrief(id: UUID) async {
        do {
            selectedBrief = try await APIService.shared.fetchBrief(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
