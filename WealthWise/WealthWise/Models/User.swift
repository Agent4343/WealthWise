import Foundation

struct AppUser: Codable, Identifiable {
    let id: UUID
    var email: String
    var fullName: String?
    var province: String?
    let createdAt: Date
    var lastActiveAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case province
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
    }
}

enum Province: String, CaseIterable, Codable {
    case ab = "AB"
    case bc = "BC"
    case mb = "MB"
    case nb = "NB"
    case nl = "NL"
    case ns = "NS"
    case nt = "NT"
    case nu = "NU"
    case on = "ON"
    case pe = "PE"
    case qc = "QC"
    case sk = "SK"
    case yt = "YT"

    var displayName: String {
        switch self {
        case .ab: return "Alberta"
        case .bc: return "British Columbia"
        case .mb: return "Manitoba"
        case .nb: return "New Brunswick"
        case .nl: return "Newfoundland and Labrador"
        case .ns: return "Nova Scotia"
        case .nt: return "Northwest Territories"
        case .nu: return "Nunavut"
        case .on: return "Ontario"
        case .pe: return "Prince Edward Island"
        case .qc: return "Quebec"
        case .sk: return "Saskatchewan"
        case .yt: return "Yukon"
        }
    }
}
