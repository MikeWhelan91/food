import Foundation

struct OpenAISmartScanService: SmartScanServicing {
    private let client: OpenAIResponsesClient
    private let fallback = MockSmartScanService()

    init(client: OpenAIResponsesClient = OpenAIResponsesClient()) {
        self.client = client
    }

    func detectItems(imageCount: Int) async throws -> [DetectedInventoryItem] {
        do {
            let json = try await client.generateJSON(prompt: """
            Create a realistic fridge or pantry smart scan result for \(imageCount) captured image(s).
            Return JSON with this exact shape:
            {"items":[{"name":"Milk","brand":"Avonmore","quantity":1,"category":"Fridge","expiryDaysFromNow":3,"confidence":0.91,"imageSystemName":"carton"}]}
            Use 3 to 6 common household grocery items. Categories must be one of Fridge, Freezer, Pantry, Bathroom, Cleaning, Pet.
            """)
            let decoded = try JSONDecoder().decode(OpenAISmartScanResponse.self, from: Data(json.utf8))
            return decoded.items.map(\.detectedItem)
        } catch ShelfServiceError.missingConfiguration {
            return try await fallback.detectItems(imageCount: imageCount)
        } catch {
            throw error
        }
    }
}

struct OpenAIReceiptOCRService: ReceiptOCRServicing {
    private let client: OpenAIResponsesClient
    private let fallback = MockReceiptOCRService()

    init(client: OpenAIResponsesClient = OpenAIResponsesClient()) {
        self.client = client
    }

    func parseReceipt() async throws -> [ReceiptLineItem] {
        do {
            let json = try await client.generateJSON(prompt: """
            Create a realistic grocery receipt extraction result.
            Return JSON with this exact shape:
            {"items":[{"name":"Milk","quantity":1,"category":"Fridge","confidence":0.94}]}
            Include 4 to 7 common grocery products. Categories must be one of Fridge, Freezer, Pantry, Bathroom, Cleaning, Pet.
            """)
            let decoded = try JSONDecoder().decode(OpenAIReceiptResponse.self, from: Data(json.utf8))
            return decoded.items.map(\.lineItem)
        } catch ShelfServiceError.missingConfiguration {
            return try await fallback.parseReceipt()
        } catch {
            throw error
        }
    }
}

struct OpenAIExpiryOCRService: ExpiryOCRServicing {
    private let client: OpenAIResponsesClient
    private let fallback = MockExpiryOCRService()

    init(client: OpenAIResponsesClient = OpenAIResponsesClient()) {
        self.client = client
    }

    func detectExpiry() async throws -> ExpiryDetection {
        do {
            let json = try await client.generateJSON(prompt: """
            Create a realistic OCR expiry extraction result from grocery packaging.
            Return JSON with this exact shape:
            {"label":"Best Before","expiryDaysFromNow":4,"rawText":"BEST BEFORE 21 MAY","confidence":0.82}
            Label must be Use By, Best Before, or Expires.
            """)
            let decoded = try JSONDecoder().decode(OpenAIExpiryResponse.self, from: Data(json.utf8))
            return decoded.expiryDetection
        } catch ShelfServiceError.missingConfiguration {
            return try await fallback.detectExpiry()
        } catch {
            throw error
        }
    }
}

private struct OpenAISmartScanResponse: Decodable {
    let items: [OpenAIDetectedItem]
}

private struct OpenAIDetectedItem: Decodable {
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

private struct OpenAIReceiptResponse: Decodable {
    let items: [OpenAIReceiptItem]
}

private struct OpenAIReceiptItem: Decodable {
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

private struct OpenAIExpiryResponse: Decodable {
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
