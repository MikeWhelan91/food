import Foundation

struct MockProductLookupService: ProductLookupServicing {
    private static let cache: [String: ProductLookupResult] = [
        "5000112548167": ProductLookupResult(barcode: "5000112548167", name: "Coke Zero", brand: "Coca-Cola", category: .pantry, imageSystemName: "bottle", confidence: 0.96, source: "Open Food Facts mock"),
        "5010255079763": ProductLookupResult(barcode: "5010255079763", name: "Semi Skimmed Milk", brand: "Avonmore", category: .fridge, imageSystemName: "carton", confidence: 0.94, source: "Local cache"),
        "0000000000012": ProductLookupResult(barcode: "0000000000012", name: "Free Range Eggs", brand: "Farmhouse", category: .fridge, imageSystemName: "oval.grid.3x3", confidence: 0.9, source: "Remote mock")
    ]

    func lookup(barcode: String) async throws -> ProductLookupResult? {
        try await Task.sleep(nanoseconds: 650_000_000)
        return Self.cache[barcode] ?? ProductLookupResult(barcode: barcode, name: "Unknown Product", brand: "", category: .pantry, imageSystemName: "barcode", confidence: 0.42, source: "Create manually")
    }
}

struct MockSmartScanService: SmartScanServicing {
    func detectItems(images: [ScanImagePayload]) async throws -> [DetectedInventoryItem] {
        try await Task.sleep(nanoseconds: 1_400_000_000)
        let imageCount = max(1, images.count)
        return [
            DetectedInventoryItem(name: "Milk", brand: "Avonmore", quantity: 1, category: .fridge, expiryDate: .daysFromNow(3), confidence: 0.92, imageSystemName: "carton"),
            DetectedInventoryItem(name: "Eggs", brand: "Farmhouse", quantity: 6, category: .fridge, expiryDate: .daysFromNow(6), confidence: 0.88, imageSystemName: "oval.grid.3x3"),
            DetectedInventoryItem(name: "Butter", brand: "Kerrygold", quantity: 1, category: .fridge, expiryDate: .daysFromNow(18), confidence: 0.84, imageSystemName: "cube"),
            DetectedInventoryItem(name: "Spinach", brand: "", quantity: 1, category: .fridge, expiryDate: .daysFromNow(1), confidence: 0.81, imageSystemName: "leaf"),
            DetectedInventoryItem(name: "Coke Zero", brand: "Coca-Cola", quantity: 4, category: .pantry, expiryDate: .daysFromNow(60), confidence: 0.86, imageSystemName: "bottle"),
            DetectedInventoryItem(name: "Yogurt", brand: "Glenisk", quantity: 2, category: .fridge, expiryDate: .daysFromNow(4), confidence: 0.79, imageSystemName: "cup.and.saucer")
        ].prefix(max(3, min(6, imageCount * 3))).map { $0 }
    }
}

struct MockReceiptOCRService: ReceiptOCRServicing {
    func parseReceipt(image: ScanImagePayload?) async throws -> [ReceiptLineItem] {
        try await Task.sleep(nanoseconds: 1_100_000_000)
        return [
            ReceiptLineItem(name: "Milk", quantity: 1, category: .fridge, confidence: 0.96),
            ReceiptLineItem(name: "Eggs", quantity: 12, category: .fridge, confidence: 0.93),
            ReceiptLineItem(name: "Bread", quantity: 1, category: .pantry, confidence: 0.91),
            ReceiptLineItem(name: "Chicken", quantity: 1, category: .fridge, confidence: 0.89),
            ReceiptLineItem(name: "Bananas", quantity: 6, category: .pantry, confidence: 0.86)
        ]
    }
}

struct MockExpiryOCRService: ExpiryOCRServicing {
    func detectExpiry(image: ScanImagePayload?) async throws -> ExpiryDetection {
        try await Task.sleep(nanoseconds: 600_000_000)
        return ExpiryDetection(date: .daysFromNow(4), label: "Best Before", rawText: "BEST BEFORE 21 MAY", confidence: 0.82)
    }
}

struct MockProductSuggestionService: ProductSuggestionServicing {
    func suggestions(from inventory: [InventoryItem], shoppingItems: [ShoppingListItem]) async -> [ShoppingListItem] {
        let existing = Set(shoppingItems.map { $0.name.lowercased() })
        let lowStock = inventory.filter { $0.quantity <= 1 }.map {
            ShoppingListItem(name: $0.productName, quantity: 1, unit: $0.unit, category: $0.category, source: "Low Stock")
        }
        let staples = ["Eggs", "Milk", "Bread"].filter { staple in
            !inventory.contains { $0.productName.localizedCaseInsensitiveContains(staple) } && !existing.contains(staple.lowercased())
        }.map {
            ShoppingListItem(name: $0, quantity: 1, category: $0 == "Bread" ? .pantry : .fridge, source: "Suggested")
        }
        return Array((lowStock + staples).prefix(5))
    }
}
