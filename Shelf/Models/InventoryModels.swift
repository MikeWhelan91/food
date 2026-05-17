import Foundation
import SwiftData

enum CategoryKind: String, Codable, CaseIterable, Identifiable {
    case fridge = "Fridge"
    case freezer = "Freezer"
    case pantry = "Pantry"
    case bathroom = "Bathroom"
    case cleaning = "Cleaning"
    case pet = "Pet"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .fridge: "refrigerator"
        case .freezer: "snowflake"
        case .pantry: "cabinet"
        case .bathroom: "shower"
        case .cleaning: "spray"
        case .pet: "pawprint"
        }
    }
}

enum InventoryUnit: String, Codable, CaseIterable {
    case each
    case pack
    case bottle
    case box
    case grams
    case kilograms
    case liters
}

enum InventoryEventKind: String, Codable {
    case added
    case consumed
    case opened
    case moved
    case edited
    case duplicated
    case deleted
}

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String
    var normalizedName: String
    var imageSystemName: String
    var imageURLString: String?
    var defaultCategory: CategoryKind
    var typicalShelfLifeDays: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        imageSystemName: String = "takeoutbag.and.cup.and.straw",
        imageURLString: String? = nil,
        defaultCategory: CategoryKind = .pantry,
        typicalShelfLifeDays: Int = 7,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.normalizedName = name.lowercased()
        self.imageSystemName = imageSystemName
        self.imageURLString = imageURLString
        self.defaultCategory = defaultCategory
        self.typicalShelfLifeDays = typicalShelfLifeDays
        self.createdAt = createdAt
    }
}

@Model
final class Barcode {
    @Attribute(.unique) var code: String
    var symbology: String
    var productName: String
    var lastResolvedAt: Date

    init(code: String, symbology: String, productName: String, lastResolvedAt: Date = .now) {
        self.code = code
        self.symbology = symbology
        self.productName = productName
        self.lastResolvedAt = lastResolvedAt
    }
}

@Model
final class ExpiryInfo {
    var date: Date?
    var label: String
    var confidence: Double
    var source: String
    var rawText: String

    init(date: Date? = nil, label: String = "Best Before", confidence: Double = 0.8, source: String = "manual", rawText: String = "") {
        self.date = date
        self.label = label
        self.confidence = confidence
        self.source = source
        self.rawText = rawText
    }
}

@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var productName: String
    var brand: String
    var quantity: Double
    var unit: InventoryUnit
    var category: CategoryKind
    var locationName: String
    var purchaseDate: Date
    var openDate: Date?
    var estimatedDepletionDate: Date?
    var notes: String
    var imageSystemName: String
    var imageURLString: String?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var expiry: ExpiryInfo?
    @Relationship(deleteRule: .cascade) var events: [InventoryEvent]

    init(
        id: UUID = UUID(),
        productName: String,
        brand: String = "",
        quantity: Double = 1,
        unit: InventoryUnit = .each,
        category: CategoryKind = .pantry,
        locationName: String = "Pantry",
        purchaseDate: Date = .now,
        openDate: Date? = nil,
        estimatedDepletionDate: Date? = nil,
        notes: String = "",
        imageSystemName: String = "takeoutbag.and.cup.and.straw",
        imageURLString: String? = nil,
        expiry: ExpiryInfo? = nil,
        events: [InventoryEvent] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.productName = productName
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.locationName = locationName
        self.purchaseDate = purchaseDate
        self.openDate = openDate
        self.estimatedDepletionDate = estimatedDepletionDate
        self.notes = notes
        self.imageSystemName = imageSystemName
        self.imageURLString = imageURLString
        self.expiry = expiry
        self.events = events
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class InventoryEvent {
    @Attribute(.unique) var id: UUID
    var kind: InventoryEventKind
    var message: String
    var quantityChange: Double
    var date: Date

    init(id: UUID = UUID(), kind: InventoryEventKind, message: String, quantityChange: Double = 0, date: Date = .now) {
        self.id = id
        self.kind = kind
        self.message = message
        self.quantityChange = quantityChange
        self.date = date
    }
}

@Model
final class ShoppingListItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    var unit: InventoryUnit
    var category: CategoryKind
    var isChecked: Bool
    var source: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, quantity: Double = 1, unit: InventoryUnit = .each, category: CategoryKind = .pantry, isChecked: Bool = false, source: String = "Manual", createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.source = source
        self.createdAt = createdAt
    }
}

@Model
final class Household {
    @Attribute(.unique) var id: UUID
    var name: String
    var cloudSyncEnabled: Bool
    var memberCount: Int

    init(id: UUID = UUID(), name: String = "Home", cloudSyncEnabled: Bool = true, memberCount: Int = 1) {
        self.id = id
        self.name = name
        self.cloudSyncEnabled = cloudSyncEnabled
        self.memberCount = memberCount
    }
}

@Model
final class ScanResult {
    @Attribute(.unique) var id: UUID
    var kind: String
    var createdAt: Date
    var summary: String
    var confidence: Double

    init(id: UUID = UUID(), kind: String, createdAt: Date = .now, summary: String, confidence: Double = 0.8) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.summary = summary
        self.confidence = confidence
    }
}

@Model
final class InventoryCategory {
    @Attribute(.unique) var id: UUID
    var kind: CategoryKind
    var displayName: String
    var sortOrder: Int

    init(id: UUID = UUID(), kind: CategoryKind, displayName: String, sortOrder: Int) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.sortOrder = sortOrder
    }
}

@Model
final class StorageLocation {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: CategoryKind
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, category: CategoryKind, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.sortOrder = sortOrder
    }
}
