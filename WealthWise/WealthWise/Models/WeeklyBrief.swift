import Foundation

struct WeeklyBrief: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let weekOf: Date
    let sectionOneSnapshot: String
    let sectionTwoMarket: String
    let sectionThreeAccounts: String
    let sectionFourLearn: String
    let sectionFiveAction: String
    let tokensUsed: Int?
    let generatedAt: Date
    let deliveredAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekOf = "week_of"
        case sectionOneSnapshot = "section_1_snapshot"
        case sectionTwoMarket = "section_2_market"
        case sectionThreeAccounts = "section_3_accounts"
        case sectionFourLearn = "section_4_learn"
        case sectionFiveAction = "section_5_action"
        case tokensUsed = "tokens_used"
        case generatedAt = "generated_at"
        case deliveredAt = "delivered_at"
    }

    var formattedWeekOf: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return "Week of \(formatter.string(from: weekOf))"
    }

    static let disclaimer = """
    WealthWise Weekly Brief is educational guidance only and does not constitute \
    personalized financial, investment, or tax advice under OSC regulations. Past \
    performance does not guarantee future results. Consult a Certified Financial \
    Planner (CFP) for advice specific to your situation.
    """
}
