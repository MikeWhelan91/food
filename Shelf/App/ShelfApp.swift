import SwiftData
import SwiftUI

@main
struct ShelfApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var dependencies = AppDependencies.live

    var sharedModelContainer: ModelContainer = {
        if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
        }

        let schema = Schema([
            Product.self,
            InventoryItem.self,
            Barcode.self,
            ShoppingListItem.self,
            Household.self,
            ScanResult.self,
            ExpiryInfo.self,
            InventoryEvent.self,
            InventoryCategory.self,
            StorageLocation.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environment(dependencies)
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light)
        }
    }
}
