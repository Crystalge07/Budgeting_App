import Foundation
import SwiftData

/// Where an entry came from.
enum EntrySource: String, Codable, CaseIterable {
    case applePay
    case manual
}

/// One logged transaction. Named `Entry` (not `Transaction`) to avoid clashing with SwiftUI's `Transaction` type.
///
/// CloudKit rules apply (sync arrives in Phase 6): every stored property has a default or is optional,
/// no unique constraints, and the relationship is optional.
@Model
final class Entry {
    var id: UUID = UUID()
    /// Positive = spend, negative = refund. Always CAD in v1.
    var amount: Decimal = 0
    var currency: String = "CAD"
    var merchant: String = ""
    var date: Date = Date.now
    var sourceRaw: String = EntrySource.manual.rawValue
    /// Card name from Wallet, or what the user typed in "Paid with" for manual entries.
    var cardName: String?
    /// nil is shown as Other.
    var category: Category?
    /// True once the user picks a category themselves.
    var categoryWasEdited: Bool = false

    init(
        amount: Decimal,
        merchant: String,
        date: Date = .now,
        source: EntrySource,
        cardName: String? = nil,
        category: Category? = nil
    ) {
        self.amount = amount
        self.merchant = merchant
        self.date = date
        self.sourceRaw = source.rawValue
        self.cardName = cardName
        self.category = category
    }

    var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var isRefund: Bool { amount < 0 }
}
