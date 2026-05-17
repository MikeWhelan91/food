import SwiftData
import SwiftUI

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [InventoryItem]
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                AppTabView(selectedTab: $selectedTab)
            } else {
                OnboardingFlow {
                    seedIfNeeded()
                    hasCompletedOnboarding = true
                }
            }
        }
        .task {
            if hasCompletedOnboarding {
                seedIfNeeded()
            }
        }
    }

    private func seedIfNeeded() {
        guard items.isEmpty else { return }
        MockData.seed(in: modelContext)
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case inventory
    case scan
    case shopping
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .inventory: "Inventory"
        case .scan: "Scan"
        case .shopping: "Shopping"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .inventory: "shippingbox"
        case .scan: "barcode.viewfinder"
        case .shopping: "checklist"
        case .settings: "gearshape"
        }
    }
}

struct AppTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.symbol) }
                .tag(AppTab.home)

            InventoryView()
                .tabItem { Label(AppTab.inventory.title, systemImage: AppTab.inventory.symbol) }
                .tag(AppTab.inventory)

            ScanHubView()
                .tabItem { Label(AppTab.scan.title, systemImage: AppTab.scan.symbol) }
                .tag(AppTab.scan)

            ShoppingView()
                .tabItem { Label(AppTab.shopping.title, systemImage: AppTab.shopping.symbol) }
                .tag(AppTab.shopping)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbol) }
                .tag(AppTab.settings)
        }
        .tint(.shelfGreen)
    }
}
