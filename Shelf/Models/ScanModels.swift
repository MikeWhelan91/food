import Foundation

struct ProductLookupResult: Identifiable, Hashable {
    let id = UUID()
    var barcode: String
    var name: String
    var brand: String
    var category: CategoryKind
    var imageSystemName: String
    var imageURL: URL? = nil
    var confidence: Double
    var source: String
}

struct DetectedInventoryItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var brand: String
    var quantity: Double
    var category: CategoryKind
    var expiryDate: Date?
    var confidence: Double
    var imageSystemName: String
}

struct ReceiptLineItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: Double
    var category: CategoryKind
    var confidence: Double
}

struct ExpiryDetection: Hashable {
    var date: Date?
    var label: String
    var rawText: String
    var confidence: Double
}
