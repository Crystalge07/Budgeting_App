import Foundation
import SwiftData

/// Seeds starter categories and rules once, and merges duplicate starter categories
/// (which can appear when two devices each seed before iCloud sync catches up).
@MainActor
enum Seeder {
    static func run(in context: ModelContext) {
        seedIfNeeded(in: context)
        mergeDuplicateStarterCategories(in: context)
        try? context.save()
    }

    static func seedIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard existing == 0 else { return }

        var byID: [UUID: Category] = [:]
        for (index, seed) in StarterData.categories.enumerated() {
            let category = Category(name: seed.name, colorHex: seed.colorHex, sortOrder: index, isDefault: true)
            category.id = seed.id
            context.insert(category)
            byID[seed.id] = category
        }
        for seed in StarterData.rules {
            let rule = MerchantRule(
                keyword: seed.keyword,
                category: byID[seed.categoryID],
                priority: seed.priority,
                isUserCreated: false
            )
            context.insert(rule)
        }
    }

    static func mergeDuplicateStarterCategories(in context: ModelContext) {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let all = try? context.fetch(descriptor) else { return }

        var kept: [UUID: Category] = [:]
        for category in all where category.isDefault {
            guard let keeper = kept[category.id] else {
                kept[category.id] = category
                continue
            }
            for entry in category.entries ?? [] {
                entry.category = keeper
            }
            for rule in category.rules ?? [] {
                if rule.isUserCreated {
                    rule.category = keeper
                } else {
                    context.delete(rule) // the keeper already has this starter rule
                }
            }
            context.delete(category)
        }
    }
}
