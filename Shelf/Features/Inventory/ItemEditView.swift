import SwiftData
import SwiftUI

enum ItemEditMode {
    case add
    case edit(InventoryItem)
}

struct ItemEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let mode: ItemEditMode
    var onSave: (() -> Void)? = nil

    @State private var name = ""
    @State private var brand = ""
    @State private var quantity = 1.0
    @State private var unit: InventoryUnit = .each
    @State private var category: CategoryKind = .pantry
    @State private var location = "Pantry"
    @State private var expiryDate = Date.daysFromNow(7)
    @State private var hasExpiry = true
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ShelfSpacing.lg) {
                    VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                        Text("Product")
                            .font(.headline)
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                        TextField("Brand", text: $brand)
                            .textInputAutocapitalization(.words)
                        Picker("Category", selection: $category) {
                            ForEach(CategoryKind.allCases) { category in
                                Label(category.rawValue, systemImage: category.symbol).tag(category)
                            }
                        }
                        TextField("Location", text: $location)
                            .textInputAutocapitalization(.words)
                    }
                    .textFieldStyle(.roundedBorder)
                    .shelfSurface(radius: 16)

                    VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                        Text("Quantity")
                            .font(.headline)
                        Stepper(value: $quantity, in: 0...99, step: 1) {
                            Text("\(quantity.formatted()) \(unit.rawValue)")
                        }
                        Picker("Unit", selection: $unit) {
                            ForEach(InventoryUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue.capitalized).tag(unit)
                            }
                        }
                    }
                    .shelfSurface(radius: 16)

                    VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                        Text("Expiry")
                            .font(.headline)
                        Toggle("Track expiry", isOn: $hasExpiry)
                        if hasExpiry {
                            DatePicker("Expiry date", selection: $expiryDate, displayedComponents: .date)
                        }
                    }
                    .shelfSurface(radius: 16)

                    VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                        Text("Notes")
                            .font(.headline)
                        TextField("Storage notes", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .shelfSurface(radius: 16)
                }
                .padding()
            }
            .background(Color.shelfCanvas)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var title: String {
        switch mode {
        case .add: "Add Item"
        case .edit: "Edit Item"
        }
    }

    private func load() {
        guard case let .edit(item) = mode, name.isEmpty else { return }
        name = item.productName
        brand = item.brand
        quantity = item.quantity
        unit = item.unit
        category = item.category
        location = item.locationName
        expiryDate = item.expiry?.date ?? .daysFromNow(7)
        hasExpiry = item.expiry?.date != nil
        notes = item.notes
    }

    private func save() {
        switch mode {
        case .add:
            let item = InventoryItem(
                productName: name,
                brand: brand,
                quantity: quantity,
                unit: unit,
                category: category,
                locationName: location,
                notes: notes,
                imageSystemName: category.symbol,
                expiry: hasExpiry ? ExpiryInfo(date: expiryDate, label: "Best Before", confidence: 1, source: "Manual") : nil,
                events: [InventoryEvent(kind: .added, message: "Added manually")]
            )
            modelContext.insert(item)
        case let .edit(item):
            item.productName = name
            item.brand = brand
            item.quantity = quantity
            item.unit = unit
            item.category = category
            item.locationName = location
            item.notes = notes
            item.updatedAt = .now
            if hasExpiry {
                if let expiry = item.expiry {
                    expiry.date = expiryDate
                    expiry.source = "Manual"
                    expiry.confidence = 1
                } else {
                    item.expiry = ExpiryInfo(date: expiryDate, label: "Best Before", confidence: 1, source: "Manual")
                }
            } else {
                item.expiry = nil
            }
            item.events.append(InventoryEvent(kind: .edited, message: "Edited item details"))
        }
        dismiss()
        onSave?()
    }
}

struct MoveItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: InventoryItem
    @State private var category: CategoryKind
    @State private var location: String

    init(item: InventoryItem) {
        self.item = item
        _category = State(initialValue: item.category)
        _location = State(initialValue: item.locationName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Category", selection: $category) {
                    ForEach(CategoryKind.allCases) { category in
                        Label(category.rawValue, systemImage: category.symbol).tag(category)
                    }
                }
                TextField("Location", text: $location)
            }
            .navigationTitle("Move Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") {
                        item.category = category
                        item.locationName = location
                        item.events.append(InventoryEvent(kind: .moved, message: "Moved to \(location)"))
                        dismiss()
                    }
                }
            }
        }
    }
}
