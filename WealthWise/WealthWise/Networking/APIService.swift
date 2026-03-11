import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Please sign in to continue"
        case .serverError(let code):
            return "Server error (\(code))"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

actor APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession
    private var authToken: String?

    private init() {
        self.baseURL = Configuration.apiBaseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Profile

    func fetchProfile() async throws -> FinancialProfile {
        return try await request(endpoint: "/profile", method: "GET")
    }

    func updateProfile(_ profile: FinancialProfile) async throws -> FinancialProfile {
        return try await request(endpoint: "/profile", method: "PUT", body: profile)
    }

    // MARK: - Briefs

    func fetchBriefs(page: Int = 0, limit: Int = 20) async throws -> [WeeklyBrief] {
        return try await request(
            endpoint: "/briefs?page=\(page)&limit=\(limit)",
            method: "GET"
        )
    }

    func fetchBrief(id: UUID) async throws -> WeeklyBrief {
        return try await request(endpoint: "/briefs/\(id.uuidString)", method: "GET")
    }

    // MARK: - Subscription

    func fetchSubscriptionStatus() async throws -> UserSubscription {
        return try await request(endpoint: "/subscription/status", method: "GET")
    }

    func syncAuth() async throws {
        let _: EmptyResponse = try await request(endpoint: "/auth/sync", method: "POST")
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: (some Encodable)? = nil as Empty?
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method

        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

private struct Empty: Encodable {}
private struct EmptyResponse: Decodable {}
