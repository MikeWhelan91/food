import SwiftData
import SwiftUI

enum InventorySort: String, CaseIterable, Identifiable {
    case expiry = "Expiry"
    case name = "Name"
    case newest = "Newest"
    case quantity = "Quantity"
    var id: String { rawValue }
}

enum InventoryLayoutMode: String, CaseIterable {
    case list
    case grid
}

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.productName) private var items: [InventoryItem]
    @State private var searchText = ""
    @State private var selectedCategory: CategoryKind?
    @State private var selectedLocation = "All"
    @State private var sort: InventorySort = .expiry
    @State private var layoutMode: InventoryLayoutMode = .list
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<UUID>()
    @State private var showingAddItem = false

    private var locations: [String] {
        ["All"] + Array(Set(items.map(\.locationName))).sorted()
    }

    private var filteredItems: [InventoryItem] {
        var result = items
        if !searchText.isEmpty {
            result = result.filter {
                $0.productName.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if selectedLocation != "All" {
            result = result.filter { $0.locationName == selectedLocation }
        }
        switch sort {
        case .expiry:
            return result.sorted { ($0.expiry?.date ?? .distantFuture) < ($1.expiry?.date ?? .distantFuture) }
        case .name:
            return result.sorted { $0.productName < $1.productName }
        case .newest:
            return result.sorted { $0.createdAt > $1.createdAt }
        case .quantity:
            return result.sorted { $0.quantity < $1.quantity }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(symbol: "shippingbox", title: "Start your inventory", message: "Scan a barcode, receipt, or shelf to add household items quickly.", actionTitle: "Add Item") {
                        showingAddItem = true
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    inventoryContent
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search items")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            layoutMode = layoutMode == .list ? .grid : .list
                        }
                    } label: {
                        Image(systemName: layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if editMode.isEditing && !selection.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete \(selection.count)", role: .destructive, action: deleteSelection)
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddItem) {
                ItemEditView(mode: .add)
            }
        }
    }

    private var inventoryContent: some View {
        ScrollView {
            VStack(spacing: ShelfSpacing.md) {
                CategoryPickerChips(selection: $selectedCategory)
                filterBar
                if filteredItems.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass", title: "No matching items", message: "Adjust your search, category, or location filters.", actionTitle: "Clear Filters", action: clearFilters)
                        .frame(maxWidth: .infinity)
                        .padding(.top, ShelfSpacing.xl)
                } else if layoutMode == .list {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                InventorySelectableRow(item: item, isEditing: editMode.isEditing, isSelected: selection.contains(item.id)) {
                                    toggle(item)
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { modelContext.delete(item) } label: { Label("Delete", systemImage: "trash") }
                                Button { duplicate(item) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                                    .tint(.shelfGreen)
                            }
                            if item.id != filteredItems.last?.id { Divider().padding(.leading, 70) }
                        }
                    }
                    .shelfSurface(radius: 18)
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: ShelfSpacing.md)], spacing: ShelfSpacing.md) {
                        ForEach(filteredItems) { item in
                            NavigationLink { ItemDetailView(item: item) } label: { InventoryGridTile(item: item) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, ShelfSpacing.xl)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var filterBar: some View {
        HStack(spacing: ShelfSpacing.sm) {
            Picker("Location", selection: $selectedLocation) {
                ForEach(locations, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            Picker("Sort", selection: $sort) {
                ForEach(InventorySort.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu)
            Spacer()
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal)
    }

    private func toggle(_ item: InventoryItem) {
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection.insert(item.id)
        }
    }

    private func deleteSelection() {
        items.filter { selection.contains($0.id) }.forEach(modelContext.delete)
        selection.removeAll()
        editMode = .inactive
    }

    private func duplicate(_ item: InventoryItem) {
        modelContext.insert(InventoryItem(productName: item.productName, brand: item.brand, quantity: item.quantity, unit: item.unit, category: item.category, locationName: item.locationName, purchaseDate: .now, imageSystemName: item.imageSystemName, expiry: ExpiryInfo(date: item.expiry?.date, label: item.expiry?.label ?? "Best Before", confidence: item.expiry?.confidence ?? 0.8, source: "Duplicate")))
    }

    private func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedLocation = "All"
    }
}

private struct InventorySelectableRow: View {
    let item: InventoryItem
    let isEditing: Bool
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        HStack {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.shelfGreen : Color.secondary)
                    .onTapGesture(perform: toggle)
            }
            InventoryItemRow(item: item)
        }
    }
}

private struct InventoryGridTile: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
            ProductThumbnail(systemName: item.imageSystemName, category: item.category, size: 54)
            Text(item.productName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(nil)
            Text(item.locationName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
            ExpiryPill(date: item.expiry?.date)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shelfSurface(radius: 16)
    }
}
