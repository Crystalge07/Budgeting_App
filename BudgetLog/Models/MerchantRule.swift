import Foundation
import SwiftData

/// "If the merchant name contains `keyword`, use `category`." Lower `priority` wins.
@Model
final class MerchantRule {
    var id: UUID = UUID()
    var keyword: String = ""
    var category: Category?
    var priority: Int = 100
    var isUserCreated: Bool = false

    init(keyword: String, category: Category?, priority: Int, isUserCreated: Bool) {
        self.keyword = keyword
        self.category = category
        self.priority = priority
        self.isUserCreated = isUserCreated
    }
}

extension CategoryResolver {
    /// The category for a merchant, or nil when no rule matches (the caller falls back to Other).
    static func category(for merchant: String, rules: [MerchantRule]) -> Category? {
        bestMatch(for: merchant, in: rules, keyword: { $0.keyword }, priority: { $0.priority })?.category
    }
}
