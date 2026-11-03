import XCTest
@testable import BudgetLog

final class CategoryResolverTests: XCTestCase {
    private struct Rule {
        let keyword: String
        let priority: Int
        let category: String
    }

    private func resolve(_ merchant: String, _ rules: [Rule]) -> String? {
        CategoryResolver.bestMatch(for: merchant, in: rules, keyword: { $0.keyword }, priority: { $0.priority })?.category
    }

    private let starter = [
        Rule(keyword: "Tim Hortons", priority: 100, category: "Food & Drink"),
        Rule(keyword: "Uber", priority: 100, category: "Transit"),
        Rule(keyword: "Uber Eats", priority: 50, category: "Food & Drink"),
        Rule(keyword: "Presto", priority: 100, category: "Transit"),
    ]

    func testMatchesMessyWalletNames() {
        XCTAssertEqual(resolve("TIM HORTONS #1234", starter), "Food & Drink")
        XCTAssertEqual(resolve("  presto   fare ", starter), "Transit")
    }

    func testLowerPriorityNumberWins() {
        XCTAssertEqual(resolve("UBER EATS TORONTO", starter), "Food & Drink")
        XCTAssertEqual(resolve("UBER TRIP", starter), "Transit")
    }

    func testLongerKeywordWinsATie() {
        let rules = [
            Rule(keyword: "Shoppers", priority: 100, category: "Shopping"),
            Rule(keyword: "Shoppers Drug Mart", priority: 100, category: "Health"),
        ]
        XCTAssertEqual(resolve("SHOPPERS DRUG MART #881", rules), "Health")
    }

    func testIgnoresAccentsAndCurlyApostrophes() {
        let rules = [
            Rule(keyword: "Café Nuvo", priority: 100, category: "Food & Drink"),
            Rule(keyword: "McDonald's", priority: 100, category: "Food & Drink"),
        ]
        XCTAssertEqual(resolve("CAFE NUVO", rules), "Food & Drink")
        XCTAssertEqual(resolve("McDonald\u{2019}s 4521", rules), "Food & Drink")
    }

    func testNoMatchReturnsNil() {
        XCTAssertNil(resolve("Local Bakery", starter))
        XCTAssertNil(resolve("", starter))
        XCTAssertNil(resolve("Anything", [Rule(keyword: "  ", priority: 0, category: "X")]))
    }
}

final class AmountInputTests: XCTestCase {
    func testParsesCommonFormats() {
        XCTAssertEqual(AmountInput.parse("4.25"), Decimal(string: "4.25"))
        XCTAssertEqual(AmountInput.parse("$4.25"), Decimal(string: "4.25"))
        XCTAssertEqual(AmountInput.parse("CA$1,234.50"), Decimal(string: "1234.50"))
        XCTAssertEqual(AmountInput.parse("1,234"), Decimal(1234))
        XCTAssertEqual(AmountInput.parse("4,25"), Decimal(string: "4.25"))
        XCTAssertEqual(AmountInput.parse(" 12 "), Decimal(12))
    }

    func testNegativeForms() {
        XCTAssertEqual(AmountInput.parse("-$3.00"), Decimal(-3))
        XCTAssertEqual(AmountInput.parse("($3.00)"), Decimal(-3))
        XCTAssertEqual(AmountInput.parse("\u{2212}3"), Decimal(-3))
    }

    func testRejectsNonNumbers() {
        XCTAssertNil(AmountInput.parse(""))
        XCTAssertNil(AmountInput.parse("abc"))
        XCTAssertNil(AmountInput.parse("."))
        XCTAssertNil(AmountInput.parse("1.2.3"))
    }
}
