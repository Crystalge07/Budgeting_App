import Foundation

/// Turns typed or Wallet-provided amounts into a Decimal.
///
/// Handles "4.25", "$4.25", "CA$1,234.50", "4,25" (comma decimal), "-$3.00" and "($3.00)".
/// Negative forms come back negative. Returns nil when there's no number.
enum AmountInput {
    static func parse(_ raw: String) -> Decimal? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var negative = false

        if text.hasPrefix("("), text.hasSuffix(")") {
            negative = true
            text = String(text.dropFirst().dropLast())
        }
        if text.contains("-") || text.contains("\u{2212}") {
            negative = true
        }

        var digits = text.filter { $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") }
        guard digits.contains(where: \.isNumber) else { return nil }

        // A comma followed by exactly two digits, with no dot, is a decimal comma ("4,25").
        if !digits.contains("."), let comma = digits.lastIndex(of: ","),
           digits.distance(from: comma, to: digits.endIndex) == 3 {
            digits.replaceSubrange(comma...comma, with: ".")
        }
        digits.removeAll { $0 == "," }

        guard digits.filter({ $0 == "." }).count <= 1,
              let value = Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX"))
        else { return nil }
        return negative ? -value : value
    }
}
