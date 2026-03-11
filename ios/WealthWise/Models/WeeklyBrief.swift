import Foundation

// MARK: - Weekly Brief

struct WeeklyBrief: Codable, Identifiable {
    let id: String
    let userId: String
    let weekStartDate: String
    let generatedAt: Date
    let title: String
    let summarySnippet: String?
    let weekAtAGlance: String
    let canadianEconomicPulse: String
    let accountsThisWeek: String
    let whatToThinkAbout: String
    let mondayActionItem: String
    let disclaimer: String
    let aiTokensUsed: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekStartDate = "week_start_date"
        case generatedAt = "generated_at"
        case title
        case summarySnippet = "summary_snippet"
        case weekAtAGlance = "week_at_a_glance"
        case canadianEconomicPulse = "canadian_economic_pulse"
        case accountsThisWeek = "accounts_this_week"
        case whatToThinkAbout = "what_to_think_about"
        case mondayActionItem = "monday_action_item"
        case disclaimer
        case aiTokensUsed = "ai_tokens_used"
        case createdAt = "created_at"
    }

    static let disclaimerText = "WealthWise Weekly Brief is educational guidance only and does not constitute personalized financial, investment, or tax advice under OSC regulations. Past performance does not guarantee future results. Consult a Certified Financial Planner (CFP) for advice specific to your situation."
}

// MARK: - Brief List Item (lightweight for list view)

struct WeeklyBriefListItem: Codable, Identifiable {
    let id: String
    let weekStartDate: String
    let generatedAt: Date
    let title: String
    let summarySnippet: String?

    enum CodingKeys: String, CodingKey {
        case id
        case weekStartDate = "week_start_date"
        case generatedAt = "generated_at"
        case title
        case summarySnippet = "summary_snippet"
    }
}

// MARK: - Briefs Pagination Response

struct BriefsResponse: Codable {
    let briefs: [WeeklyBriefListItem]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case totalPages = "total_pages"
    }
}
