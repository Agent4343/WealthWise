import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case unauthorized
    case forbidden(String?)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case .noData: return "No data received from server."
        case .decodingError(let err): return "Failed to parse server response: \(err.localizedDescription)"
        case .serverError(let code, let message): return message ?? "Server error (\(code))."
        case .unauthorized: return "Your session has expired. Please sign in again."
        case .forbidden(let message): return message ?? "You don't have permission to access this feature."
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .unknown: return "An unexpected error occurred."
        }
    }
}

// MARK: - API Service

final class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder

    private init(baseURL: String = Config.apiBaseURL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            // Try ISO8601 with fractional seconds first, then without
            let formatters: [ISO8601DateFormatter] = [
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return f
                }(),
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime]
                    return f
                }(),
            ]
            for formatter in formatters {
                if let date = formatter.date(from: dateStr) { return date }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateStr)")
        }
    }

    // MARK: - Auth Sync

    func syncUser(token: String) async throws -> AppUser {
        let response: SyncUserResponse = try await post(path: "/auth/sync", token: token, body: EmptyBody())
        return response.user
    }

    // MARK: - Profile

    func getProfile(token: String) async throws -> FinancialProfile? {
        let response: ProfileResponse = try await get(path: "/profile", token: token)
        return response.profile
    }

    func updateProfile(token: String, updates: ProfileUpdateRequest) async throws -> FinancialProfile {
        let response: ProfileResponse = try await put(path: "/profile", token: token, body: updates)
        return response.profile!
    }

    // MARK: - Weekly Briefs

    func getBriefs(token: String, page: Int = 1) async throws -> BriefsResponse {
        return try await get(path: "/briefs?page=\(page)", token: token)
    }

    func getBrief(token: String, id: String) async throws -> WeeklyBrief {
        let response: BriefDetailResponse = try await get(path: "/briefs/\(id)", token: token)
        return response.brief
    }

    // MARK: - Generic HTTP Methods

    private func get<T: Decodable>(path: String, token: String) async throws -> T {
        let request = try buildRequest(method: "GET", path: path, token: token, body: nil as EmptyBody?)
        return try await execute(request)
    }

    private func post<T: Decodable, B: Encodable>(path: String, token: String, body: B) async throws -> T {
        let request = try buildRequest(method: "POST", path: path, token: token, body: body)
        return try await execute(request)
    }

    private func put<T: Decodable, B: Encodable>(path: String, token: String, body: B) async throws -> T {
        let request = try buildRequest(method: "PUT", path: path, token: token, body: body)
        return try await execute(request)
    }

    private func buildRequest<B: Encodable>(method: String, path: String, token: String, body: B?) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        if let body = body, !(body is EmptyBody) {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try jsonDecoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.unauthorized
            case 403:
                let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.forbidden(errorBody?.error)
            default:
                let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(httpResponse.statusCode, errorBody?.error)
            }
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Request / Response Models

private struct EmptyBody: Encodable {}

private struct SyncUserResponse: Decodable {
    let user: AppUser
}

private struct ProfileResponse: Decodable {
    let profile: FinancialProfile?
}

private struct BriefDetailResponse: Decodable {
    let brief: WeeklyBrief
}

private struct ErrorResponse: Decodable {
    let error: String
}

struct ProfileUpdateRequest: Encodable {
    var currentAge: Int?
    var targetRetirementAge: Int?
    var province: String?
    var incomeBracket: String?
    var tfsaRoomUsed: Double?
    var rrspRoomAvailable: Double?
    var currentSavingsBalance: Double?
    var currentRrspBalance: Double?
    var currentTfsaBalance: Double?
    var monthlySavingsAmount: Double?
    var monthlySavingsTarget: Double?
    var riskTolerance: String?

    enum CodingKeys: String, CodingKey {
        case currentAge = "current_age"
        case targetRetirementAge = "target_retirement_age"
        case province
        case incomeBracket = "income_bracket"
        case tfsaRoomUsed = "tfsa_room_used"
        case rrspRoomAvailable = "rrsp_room_available"
        case currentSavingsBalance = "current_savings_balance"
        case currentRrspBalance = "current_rrsp_balance"
        case currentTfsaBalance = "current_tfsa_balance"
        case monthlySavingsAmount = "monthly_savings_amount"
        case monthlySavingsTarget = "monthly_savings_target"
        case riskTolerance = "risk_tolerance"
    }
}
