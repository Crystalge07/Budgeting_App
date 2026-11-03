import Foundation

/// Picks the merchant rule that applies to a merchant name.
///
/// Pure logic with no SwiftData or UI dependency, so it can be unit tested.
/// Matching: case- and accent-insensitive "merchant contains keyword".
/// The lowest priority number wins; on a tie the longer (more specific) keyword wins; then the first rule.
enum CategoryResolver {
    static func bestMatch<Rule>(
        for merchant: String,
        in rules: [Rule],
        keyword: (Rule) -> String,
        priority: (Rule) -> Int
    ) -> Rule? {
        let name = normalize(merchant)
        guard !name.isEmpty else { return nil }

        var best: (rule: Rule, priority: Int, length: Int)?
        for rule in rules {
            let key = normalize(keyword(rule))
            guard !key.isEmpty, name.contains(key) else { continue }
            let p = priority(rule)
            if let current = best, (current.priority, -current.length) <= (p, -key.count) {
                continue
            }
            best = (rule, p, key.count)
        }
        return best?.rule
    }

    static func normalize(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_CA"))
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
