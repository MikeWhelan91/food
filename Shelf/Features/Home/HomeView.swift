import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \InventoryItem.createdAt, order: .reverse) private var items: [InventoryItem]
    @Query(sort: \ShoppingListItem.createdAt, order: .reverse) private var shoppingItems: [ShoppingListItem]

    private var expiringSoon: [InventoryItem] {
        items.filter { item in
            [.soon, .urgent, .expired].contains(ExpiryFormatter.urgency(for: item.expiry?.date))
        }
        .sorted { ($0.expiry?.date ?? .distantFuture) < ($1.expiry?.date ?? .distantFuture) }
    }

    private var lowStock: [InventoryItem] {
        items.filter { $0.quantity <= 1 }.prefix(4).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ShelfSpacing.lg) {
                    HomeHeader(itemCount: items.count, expiringCount: expiringSoon.count)
                    SmartInsight(item: expiringSoon.first)
                    ExpiringSoonModule(items: Array(expiringSoon.prefix(5)))
                    CompactItemModule(title: "Low Stock", emptyText: "No low stock items", items: lowStock)
                    CompactItemModule(title: "Recently Added", emptyText: "Add your first item", items: Array(items.prefix(4)))
                    ShoppingSuggestionsModule(items: Array(shoppingItems.filter { !$0.isChecked }.prefix(4)))
                }
                .padding(.horizontal)
                .padding(.bottom, ShelfSpacing.xl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Shelf")
        }
    }
}

private struct HomeHeader: View {
    let itemCount: Int
    let expiringCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.md) {
            Text("Good \(greetingPeriod)")
                .font(.title2.weight(.semibold))
            HStack(spacing: ShelfSpacing.md) {
                StatBlock(value: "\(itemCount)", label: "Tracked")
                StatBlock(value: "\(expiringCount)", label: "Expiring")
            }
        }
        .padding(.top, ShelfSpacing.sm)
    }

    private var greetingPeriod: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "morning" }
        if hour < 18 { return "afternoon" }
        return "evening"
    }
}

private struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shelfSurface(radius: 14)
    }
}

private struct SmartInsight: View {
    let item: InventoryItem?

    var body: some View {
        HStack(spacing: ShelfSpacing.md) {
            Image(systemName: "lightbulb")
                .font(.title3)
                .foregroundStyle(Color.shelfAmber)
            Text(text)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: ShelfSpacing.sm)
        }
        .shelfSurface(radius: 16)
    }

    private var text: String {
        if let item {
            return "\(item.productName) \(ExpiryFormatter.relativeText(for: item.expiry?.date).lowercased())."
        }
        return "You usually restock eggs every 6 days."
    }
}

private struct ExpiringSoonModule: View {
    let items: [InventoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.md) {
            SectionHeader(title: "Expiring Soon")
            if let first = items.first {
                FeaturedExpiryItem(item: first)
                VStack(spacing: 0) {
                    ForEach(items.dropFirst()) { item in
                        InventoryItemRow(item: item, compact: true)
                        if item.id != items.last?.id { Divider().padding(.leading, 54) }
                    }
                }
                .shelfSurface(radius: 16)
            } else {
                EmptyStateView(symbol: "checkmark.seal", title: "Nothing urgent", message: "Items with close expiry dates will appear here.", actionTitle: "Scan Items") {}
                    .frame(maxWidth: .infinity)
                    .shelfSurface(radius: 16)
            }
        }
    }
}

private struct FeaturedExpiryItem: View {
    let item: InventoryItem

    var body: some View {
        HStack(alignment: .center, spacing: ShelfSpacing.md) {
            ProductThumbnail(systemName: item.imageSystemName, category: item.category, size: 64)
            VStack(alignment: .leading, spacing: ShelfSpacing.xs) {
                Text(item.productName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(nil)
                Text(item.locationName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ExpiryPill(date: item.expiry?.date)
            }
            Spacer()
        }
        .padding(ShelfSpacing.md)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CompactItemModule: View {
    let title: String
    let emptyText: String
    let items: [InventoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
            SectionHeader(title: title)
            VStack(spacing: 0) {
                if items.isEmpty {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, ShelfSpacing.sm)
                } else {
                    ForEach(items) { item in
                        InventoryItemRow(item: item, compact: true)
                        if item.id != items.last?.id { Divider().padding(.leading, 54) }
                    }
                }
            }
            .shelfSurface(radius: 16)
        }
    }
}

private struct ShoppingSuggestionsModule: View {
    let items: [ShoppingListItem]

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
            SectionHeader(title: "Shopping Suggestions")
            VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                ForEach(items) { item in
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color.shelfGreen)
                        Text(item.name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(item.source)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if items.isEmpty {
                    Text("Suggestions appear when Shelf notices low stock or restock patterns.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .shelfSurface(radius: 16)
        }
    }
}
