import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "System"
    @AppStorage("expiryNotifications") private var expiryNotifications = true
    @AppStorage("smartFeatures") private var smartFeatures = true
    @State private var cloudSync = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SettingsProfileRow()
                }
                Section("Notifications") {
                    Toggle("Expiry reminders", isOn: $expiryNotifications)
                    NavigationLink("Reminder timing") {
                        SettingsDetailPlaceholder(title: "Reminder Timing", message: "Choose when Shelf reminds you about expiring items.")
                    }
                }
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceMode) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    NavigationLink("App icon") {
                        SettingsDetailPlaceholder(title: "App Icon", message: "Alternate app icons can be added here.")
                    }
                }
                Section("Inventory") {
                    NavigationLink("Categories") {
                        CategorySettingsView()
                    }
                    NavigationLink("Household") {
                        SettingsDetailPlaceholder(title: "Household", message: "Invite household members and manage shared spaces.")
                    }
                }
                Section("Intelligence") {
                    Toggle("AI features", isOn: $smartFeatures)
                    NavigationLink("Smart scan preferences") {
                        SettingsDetailPlaceholder(title: "AI Features", message: "Control local and cloud-assisted inventory detection.")
                    }
                }
                Section("Data") {
                    Toggle("Cloud Sync", isOn: $cloudSync)
                    NavigationLink("Export Data") {
                        SettingsDetailPlaceholder(title: "Export Data", message: "Export inventory and shopping history as a file.")
                    }
                }
                Section {
                    NavigationLink("About Shelf") {
                        SettingsDetailPlaceholder(title: "About Shelf", message: "Version 1.0")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct SettingsProfileRow: View {
    var body: some View {
        HStack(spacing: ShelfSpacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.shelfGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Alex")
                    .font(.headline)
                Text("Personal household")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CategorySettingsView: View {
    var body: some View {
        List {
            ForEach(CategoryKind.allCases) { category in
                Label(category.rawValue, systemImage: category.symbol)
            }
        }
        .navigationTitle("Categories")
    }
}

private struct SettingsDetailPlaceholder: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: ShelfSpacing.md) {
            Image(systemName: "gearshape")
                .font(.largeTitle)
                .foregroundStyle(Color.shelfGreen)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ShelfSpacing.xl)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
