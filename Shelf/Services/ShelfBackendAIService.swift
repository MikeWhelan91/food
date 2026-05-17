import Foundation

struct ShelfBackendSmartScanService: SmartScanServicing {
    private let client: ShelfBackendAIClient
    private let fallback = MockSmartScanService()

    init(client: ShelfBackendAIClient = ShelfBackendAIClient()) {
        self.client = client
    }

    func detectItems(imageCount: Int) async throws -> [DetectedInventoryItem] {
        do {
            let response = try await client.post(
                "api/ai/smart-scan",
                body: SmartScanRequest(imageCount: imageCount),
                responseType: SmartScanResponse.self
            )
            return response.items.map(\.detectedItem)
        } catch ShelfServiceError.missingConfiguration {
            return try await fallback.detectItems(imageCount: imageCount)
        }
    }
}

struct ShelfBackendReceiptOCRService: ReceiptOCRServicing {
    private let client: ShelfBackendAIClient
    private let fallback = MockReceiptOCRService()

    init(client: ShelfBackendAIClient = ShelfBackendAIClient()) {
        self.client = client
    }

    func parseReceipt() async throws -> [ReceiptLineItem] {
        do {
            let response = try await client.post(
                "api/ai/receipt",
                body: EmptyAIRequest(),
                responseType: ReceiptResponse.self
            )
            return response.items.map(\.lineItem)
        } catch ShelfServiceError.missingConfiguration {
            return try await fallback.parseReceipt()
        }
    }
}

struct ShelfBackendExpiryOCRService: ExpiryOCRServicing {
    private let client: ShelfBackendAIClient
    private let fallback = MockExpiryOCRService()

    init(client: ShelfBackendAIClient = ShelfBackendAIClient()) {
        self.client = client
    }

    func detectExpiry() async throws -> ExpiryDetection {
        do {
            let response = try await client.post(
                "api/ai/expiry",
                body: EmptyAIRequest(),
                responseType: ExpiryResponse.self
            )
            return response.expiryDetection
        } catch ShelfServiceError.missingConfiguration {
            return try await fallback.detectExpiry()
        }
    }
}

private struct EmptyAIRequest: Encodable {}

private struct SmartScanRequest: Encodable {
    let imageCount: Int
}

private struct SmartScanResponse: Decodable {
    let items: [BackendDetectedItem]
}

private struct BackendDetectedItem: Decodable {
    let name: String
    let brand: String?
    let quantity: Double
    let category: String
    let expiryDaysFromNow: Int?
    let confidence: Double
    let imageSystemName: String?

    var detectedItem: DetectedInventoryItem {
        DetectedInventoryItem(
            name: name,
            brand: brand ?? "",
            quantity: quantity,
            category: CategoryKind(rawValue: category) ?? .pantry,
            expiryDate: expiryDaysFromNow.map(Date.daysFromNow),
            confidence: min(max(confidence, 0), 1),
            imageSystemName: imageSystemName ?? (CategoryKind(rawValue: category) ?? .pantry).symbol
        )
    }
}

private struct ReceiptResponse: Decodable {
    let items: [BackendReceiptItem]
}

private struct BackendReceiptItem: Decodable {
    let name: String
    let quantity: Double
    let category: String
    let confidence: Double

    var lineItem: ReceiptLineItem {
        ReceiptLineItem(
            name: name,
            quantity: quantity,
            category: CategoryKind(rawValue: category) ?? .pantry,
            confidence: min(max(confidence, 0), 1)
        )
    }
}

private struct ExpiryResponse: Decodable {
    let label: String
    let expiryDaysFromNow: Int?
    let rawText: String
    let confidence: Double

    var expiryDetection: ExpiryDetection {
        ExpiryDetection(
            date: expiryDaysFromNow.map(Date.daysFromNow),
            label: label,
            rawText: rawText,
            confidence: min(max(confidence, 0), 1)
        )
    }
}
