import Foundation

/// Categories and merchant rules seeded on first launch.
enum StarterData {
    struct CategorySeed {
        let id: UUID
        let name: String
        let colorHex: String
    }

    struct RuleSeed {
        let keyword: String
        let categoryID: UUID
        let priority: Int
    }

    // Fixed ids so the same starter category seeded on two devices can be merged after iCloud sync.
    static let foodID = UUID(uuidString: "A5585D65-EA90-4636-BEF8-F4B36593B442")!
    static let groceriesID = UUID(uuidString: "3879EF22-6724-424E-B6D8-22D9E19BDB51")!
    static let transitID = UUID(uuidString: "AF465EB1-7422-4FE5-87B7-485AE43A17C2")!
    static let shoppingID = UUID(uuidString: "AEFAE133-193B-4A2A-BCF8-FA5C5697AB71")!
    static let entertainmentID = UUID(uuidString: "7DE28BEC-F036-4BA1-958D-9B81B55A63DE")!
    static let billsID = UUID(uuidString: "D852419D-AB9B-4161-A2E3-2F5164606D30")!
    static let healthID = UUID(uuidString: "4F638D86-9DE3-45B6-BE60-3A9DB3988112")!
    static let otherID = UUID(uuidString: "B18C3692-2A67-457B-81AE-618D1E55A7A4")!

    static let otherColorHex = "#8E8E93"

    static let categories: [CategorySeed] = [
        CategorySeed(id: foodID, name: "Food & Drink", colorHex: "#FF9500"),
        CategorySeed(id: groceriesID, name: "Groceries", colorHex: "#34C759"),
        CategorySeed(id: transitID, name: "Transit", colorHex: "#007AFF"),
        CategorySeed(id: shoppingID, name: "Shopping", colorHex: "#AF52DE"),
        CategorySeed(id: entertainmentID, name: "Entertainment", colorHex: "#FF2D55"),
        CategorySeed(id: billsID, name: "Bills", colorHex: "#5856D6"),
        CategorySeed(id: healthID, name: "Health", colorHex: "#00C7BE"),
        CategorySeed(id: otherID, name: "Other", colorHex: otherColorHex),
    ]

    /// Default priority is 100. "Uber Eats" uses 50 so it beats "Uber" → Transit.
    static let rules: [RuleSeed] = {
        func r(_ keyword: String, _ id: UUID, _ priority: Int = 100) -> RuleSeed {
            RuleSeed(keyword: keyword, categoryID: id, priority: priority)
        }
        return [
            // Food & Drink
            r("Tim Hortons", foodID), r("Starbucks", foodID), r("McDonald", foodID),
            r("A&W", foodID), r("Subway", foodID), r("Second Cup", foodID),
            r("DoorDash", foodID), r("Uber Eats", foodID, 50), r("Skip The Dishes", foodID),
            // Groceries
            r("Loblaws", groceriesID), r("No Frills", groceriesID), r("Sobeys", groceriesID),
            r("FreshCo", groceriesID), r("Farm Boy", groceriesID), r("Food Basics", groceriesID),
            r("Metro", groceriesID), r("Costco", groceriesID), r("T&T", groceriesID),
            // Transit
            r("Presto", transitID), r("Uber", transitID), r("Lyft", transitID),
            r("TTC", transitID), r("GO Transit", transitID), r("Petro-Canada", transitID),
            // Shopping
            r("Amazon", shoppingID), r("Walmart", shoppingID), r("Winners", shoppingID),
            r("Canadian Tire", shoppingID), r("Indigo", shoppingID), r("Dollarama", shoppingID),
            // Entertainment
            r("Netflix", entertainmentID), r("Spotify", entertainmentID), r("Cineplex", entertainmentID),
            // Bills
            r("Rogers", billsID), r("Bell Canada", billsID), r("Bell Mobility", billsID),
            r("Fido", billsID), r("Hydro", billsID),
            // Health
            r("Shoppers Drug Mart", healthID), r("Rexall", healthID),
        ]
    }()
}
