import SwiftUI
import SwiftData

@main
struct BudgetLogApp: App {
    var body: some Scene {
        WindowGroup {
            LogView()
        }
        .modelContainer(Persistence.shared)
    }
}

/// One container shared by the app and (from Phase 2) the Log Transaction intent,
/// so intent writes show up in the UI right away.
enum Persistence {
    @MainActor
    static let shared: ModelContainer = {
        let schema = Schema([Entry.self, Category.self, MerchantRule.self])
        // Phase 6 switches this to `.automatic` for iCloud sync (needs the paid developer account).
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            Seeder.run(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not open the data store: \(error)")
        }
    }()
}
