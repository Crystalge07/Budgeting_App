import SwiftUI

enum Money {
    /// v1 is CAD only.
    static let currencyCode = "CAD"

    static func format(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: currencyCode))
    }

    /// Plain editable text for a form field, e.g. 4.25 → "4.25".
    static func editableText(_ amount: Decimal) -> String {
        abs(amount).formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(Locale(identifier: "en_US_POSIX")))
    }
}

extension Color {
    /// "#RRGGBB" → Color. Falls back to gray for anything else.
    init(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#") { text.removeFirst() }
        var value: UInt64 = 0
        guard text.count == 6, Scanner(string: text).scanHexInt64(&value) else {
            self = .gray
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
