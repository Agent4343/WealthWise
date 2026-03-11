import Foundation

// MARK: - Briefs ViewModel

@MainActor
final class BriefsViewModel: ObservableObject {
    @Published var briefs: [WeeklyBriefListItem] = []
    @Published var selectedBrief: WeeklyBrief?
    @Published var isLoading: Bool = false
    @Published var isLoadingDetail: Bool = false
    @Published var errorMessage: String?
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var hasLoadedOnce: Bool = false

    private let authManager = AuthManager.shared

    func loadBriefs(refresh: Bool = false) async {
        guard let token = authManager.accessToken else { return }

        if refresh {
            currentPage = 1
            briefs = []
        }

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.getBriefs(token: token, page: currentPage)
            if refresh {
                briefs = response.briefs
            } else {
                briefs.append(contentsOf: response.briefs)
            }
            totalPages = response.pagination.totalPages
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBriefDetail(id: String) async {
        guard let token = authManager.accessToken else { return }

        isLoadingDetail = true
        defer { isLoadingDetail = false }

        do {
            selectedBrief = try await APIService.shared.getBrief(token: token, id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNextPage() async {
        guard currentPage < totalPages else { return }
        currentPage += 1
        await loadBriefs()
    }
}
