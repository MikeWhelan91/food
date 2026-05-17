import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: InventoryItem
    @State private var showingEdit = false
    @State private var showingMove = false
    @State private var consumptionAmount = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ShelfSpacing.lg) {
                ItemHero(item: item)
                primaryActions
                DetailSection(title: "Details") {
                    DetailRow("Brand", value: item.brand.isEmpty ? "Not set" : item.brand)
                    DetailRow("Quantity", value: "\(item.quantity.formatted()) \(item.unit.rawValue)")
                    DetailRow("Expiry", value: ExpiryFormatter.relativeText(for: item.expiry?.date))
                    DetailRow("Purchased", value: item.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    DetailRow("Estimated depletion", value: item.estimatedDepletionDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not enough history")
                    DetailRow("Location", value: item.locationName)
                    if let openDate = item.openDate {
                        DetailRow("Opened", value: openDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                if !item.notes.isEmpty {
                    DetailSection(title: "Notes") {
                        Text(item.notes)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                DetailSection(title: "History") {
                    if item.events.isEmpty {
                        Text("No history yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(item.events.sorted { $0.date > $1.date }) { event in
                            HStack(alignment: .top, spacing: ShelfSpacing.sm) {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.message)
                                        .font(.subheadline.weight(.medium))
                                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.productName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button("Edit", systemImage: "pencil") { showingEdit = true }
                Button("Duplicate", systemImage: "plus.square.on.square", action: duplicate)
                Button("Move", systemImage: "folder") { showingMove = true }
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showingEdit) {
            ItemEditView(mode: .edit(item))
        }
        .sheet(isPresented: $showingMove) {
            MoveItemView(item: item)
        }
    }

    private var primaryActions: some View {
        VStack(spacing: ShelfSpacing.sm) {
            Stepper(value: $consumptionAmount, in: 0.25...max(1, item.quantity), step: 0.25) {
                Text("Consume \(consumptionAmount.formatted()) \(item.unit.rawValue)")
                    .font(.subheadline.weight(.medium))
            }
            Button(action: consume) {
                Label("Consume", systemImage: "minus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .shelfSurface(radius: 16)
    }

    private func consume() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            item.quantity = max(0, item.quantity - consumptionAmount)
            item.updatedAt = .now
            item.events.append(InventoryEvent(kind: .consumed, message: "Consumed \(consumptionAmount.formatted()) \(item.unit.rawValue)", quantityChange: -consumptionAmount))
        }
    }

    private func duplicate() {
        modelContext.insert(InventoryItem(productName: item.productName, brand: item.brand, quantity: item.quantity, unit: item.unit, category: item.category, locationName: item.locationName, purchaseDate: .now, imageSystemName: item.imageSystemName, imageURLString: item.imageURLString, expiry: ExpiryInfo(date: item.expiry?.date, label: item.expiry?.label ?? "Best Before", confidence: item.expiry?.confidence ?? 0.7, source: "Duplicate"), events: [InventoryEvent(kind: .duplicated, message: "Duplicated from \(item.productName)")]))
    }

    private func delete() {
        modelContext.delete(item)
        dismiss()
    }
}

private struct ItemHero: View {
    let item: InventoryItem

    var body: some View {
        HStack(alignment: .center, spacing: ShelfSpacing.lg) {
            ProductThumbnail(systemName: item.imageSystemName, category: item.category, size: 86, imageURLString: item.imageURLString)
            VStack(alignment: .leading, spacing: ShelfSpacing.xs) {
                Text(item.productName)
                    .font(.title2.weight(.bold))
                    .lineLimit(nil)
                Text(item.brand.isEmpty ? item.category.rawValue : item.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ExpiryPill(date: item.expiry?.date)
            }
            Spacer()
        }
        .shelfSurface(radius: 20)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.md) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                content
            }
            .shelfSurface(radius: 16)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: ShelfSpacing.md)
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
    }
}
