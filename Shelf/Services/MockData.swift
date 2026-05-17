import Foundation
import SwiftData

enum MockData {
    static func seed(in context: ModelContext) {
        let items = [
            InventoryItem(productName: "Strawberries", brand: "Keelings", quantity: 1, unit: .pack, category: .fridge, locationName: "Fridge drawer", purchaseDate: .daysFromNow(-2), estimatedDepletionDate: .daysFromNow(1), notes: "Opened after lunch.", imageSystemName: "leaf", expiry: ExpiryInfo(date: .daysFromNow(1), label: "Use By", confidence: 0.91, source: "OCR", rawText: "USE BY 18 MAY"), events: [InventoryEvent(kind: .added, message: "Added from receipt")]),
            InventoryItem(productName: "Semi Skimmed Milk", brand: "Avonmore", quantity: 1, unit: .bottle, category: .fridge, locationName: "Fridge door", purchaseDate: .daysFromNow(-1), estimatedDepletionDate: .daysFromNow(3), imageSystemName: "takeoutbag.and.cup.and.straw", expiry: ExpiryInfo(date: .daysFromNow(3), label: "Best Before", confidence: 0.86, source: "Barcode", rawText: "")),
            InventoryItem(productName: "Eggs", brand: "Farmhouse", quantity: 6, unit: .each, category: .fridge, locationName: "Top shelf", purchaseDate: .daysFromNow(-3), estimatedDepletionDate: .daysFromNow(4), imageSystemName: "circle.grid.3x3", expiry: ExpiryInfo(date: .daysFromNow(6), label: "Best Before", confidence: 0.75, source: "Manual", rawText: "")),
            InventoryItem(productName: "Sourdough", brand: "Bread 41", quantity: 0.5, unit: .each, category: .pantry, locationName: "Bread bin", purchaseDate: .daysFromNow(-2), estimatedDepletionDate: .daysFromNow(1), imageSystemName: "birthday.cake", expiry: ExpiryInfo(date: .daysFromNow(2), label: "Best Before", confidence: 0.68, source: "Receipt", rawText: "")),
            InventoryItem(productName: "Laundry Capsules", brand: "Ecover", quantity: 8, unit: .pack, category: .cleaning, locationName: "Utility press", purchaseDate: .daysFromNow(-12), imageSystemName: "washer", expiry: nil),
            InventoryItem(productName: "Dog Food", brand: "Burns", quantity: 1, unit: .pack, category: .pet, locationName: "Hall press", purchaseDate: .daysFromNow(-8), imageSystemName: "pawprint", expiry: ExpiryInfo(date: .daysFromNow(40), label: "Best Before", confidence: 0.8, source: "Manual", rawText: ""))
        ]
        items.forEach(context.insert)
        [
            ShoppingListItem(name: "Olive Oil", quantity: 1, unit: .bottle, category: .pantry, source: "Manual"),
            ShoppingListItem(name: "Spinach", quantity: 1, unit: .pack, category: .fridge, source: "Suggested"),
            ShoppingListItem(name: "Kitchen Roll", quantity: 1, unit: .pack, category: .cleaning, source: "Manual")
        ].forEach(context.insert)
        CategoryKind.allCases.enumerated().forEach { index, kind in
            context.insert(InventoryCategory(kind: kind, displayName: kind.rawValue, sortOrder: index))
        }
        context.insert(Household())
    }
}
