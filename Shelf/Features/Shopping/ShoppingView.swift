import SwiftData
import SwiftUI

enum ShoppingSection: String, CaseIterable, Identifiable {
    case suggested = "Suggested"
    case lowStock = "Low Stock"
    case manual = "Manual"
    case recent = "Recent"
    var id: String { rawValue }
}

struct ShoppingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \InventoryItem.productName) private var inventory: [InventoryItem]
    @Query(sort: \ShoppingListItem.createdAt, order: .reverse) private var items: [ShoppingListItem]
    @State private var selectedSection: ShoppingSection = .suggested
    @State private var newItemName = ""
    @State private var shoppingMode = false
    @State private var suggestions: [ShoppingListItem] = []

    private var visibleItems: [ShoppingListItem] {
        let source: String
        switch selectedSection {
        case .suggested: source = "Suggested"
        case .lowStock: source = "Low Stock"
        case .manual: source = "Manual"
        case .recent: source = "Purchased Recently"
        }
        return items.filter { $0.source == source || (selectedSection == .recent && $0.isChecked) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if shoppingMode {
                    ShoppingModeList(items: visibleItems.isEmpty ? items : visibleItems)
                } else {
                    standardContent
                }
            }
            .navigationTitle(shoppingMode ? "Shopping Mode" : "Shopping")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(shoppingMode ? "Done" : "Mode") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            shoppingMode.toggle()
                        }
                    }
                }
            }
            .task {
                suggestions = await dependencies.suggestions.suggestions(from: inventory, shoppingItems: items)
            }
        }
    }

    private var standardContent: some View {
        ScrollView {
            VStack(spacing: ShelfSpacing.md) {
                Picker("Section", selection: $selectedSection) {
                    ForEach(ShoppingSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                addItemBar

                if selectedSection == .suggested && !suggestions.isEmpty {
                    ShoppingSuggestionList(suggestions: suggestions, add: addSuggestion)
                        .padding(.horizontal)
                }

                if visibleItems.isEmpty {
                    EmptyStateView(symbol: "cart", title: "Nothing here yet", message: "Add manual items or accept smart suggestions as Shelf learns your restock patterns.", actionTitle: "Add Item", action: addManual)
                        .frame(maxWidth: .infinity)
                        .padding(.top, ShelfSpacing.xl)
                } else {
                    VStack(spacing: 0) {
                        ForEach(visibleItems) { item in
                            ShoppingRow(item: item)
                            if item.id != visibleItems.last?.id { Divider().padding(.leading, 44) }
                        }
                    }
                    .shelfSurface(radius: 18)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, ShelfSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var addItemBar: some View {
        HStack(spacing: ShelfSpacing.sm) {
            TextField("Add item", text: $newItemName)
                .textFieldStyle(.roundedBorder)
            Button(action: addManual) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
    }

    private func addManual() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(ShoppingListItem(name: trimmed, source: "Manual"))
        newItemName = ""
        dependencies.haptics.selection()
    }

    private func addSuggestion(_ suggestion: ShoppingListItem) {
        modelContext.insert(ShoppingListItem(name: suggestion.name, quantity: suggestion.quantity, unit: suggestion.unit, category: suggestion.category, source: suggestion.source))
        dependencies.haptics.selection()
    }
}

private struct ShoppingRow: View {
    @Bindable var item: ShoppingListItem

    var body: some View {
        HStack(spacing: ShelfSpacing.md) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    item.isChecked.toggle()
                }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? Color.shelfGreen : Color.secondary)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .strikethrough(item.isChecked)
                Text(item.source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Stepper("\(item.quantity.formatted())", value: $item.quantity, in: 0...99, step: 1)
                .labelsHidden()
        }
        .padding(.vertical, 10)
    }
}

private struct ShoppingSuggestionList: View {
    let suggestions: [ShoppingListItem]
    let add: (ShoppingListItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
            Text("Suggested").font(.headline)
            ForEach(suggestions) { suggestion in
                HStack {
                    ProductThumbnail(systemName: suggestion.category.symbol, category: suggestion.category, size: 38)
                    VStack(alignment: .leading) {
                        Text(suggestion.name).font(.subheadline.weight(.medium))
                        Text(suggestion.source).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { add(suggestion) } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.shelfGreen)
                }
            }
        }
        .shelfSurface(radius: 18)
    }
}

private struct ShoppingModeList: View {
    let items: [ShoppingListItem]

    var body: some View {
        List {
            ForEach(items) { item in
                ShoppingModeRow(item: item)
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct ShoppingModeRow: View {
    @Bindable var item: ShoppingListItem

    var body: some View {
        Button {
            item.isChecked.toggle()
        } label: {
            HStack(spacing: ShelfSpacing.md) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? Color.shelfGreen : Color.secondary)
                Text(item.name)
                    .font(.title3.weight(.semibold))
                    .strikethrough(item.isChecked)
                    .lineLimit(nil)
                Spacer()
                Text(item.quantity.formatted())
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
