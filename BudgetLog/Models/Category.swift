import Foundation
import SwiftData

@Model
final class Category {
    /// Starter categories use fixed ids from `StarterData`, so copies seeded on two devices can be merged.
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#8E8E93"
    var sortOrder: Int = 0
    var isDefault: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Entry.category)
    var entries: [Entry]? = []

    @Relationship(deleteRule: .cascade, inverse: \MerchantRule.category)
    var rules: [MerchantRule]? = []

    init(name: String, colorHex: String, sortOrder: Int, isDefault: Bool = false) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }

    var isOther: Bool { id == StarterData.otherID }
}
