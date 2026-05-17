import Foundation
import SwiftUI
import UserNotifications

protocol ProductLookupServicing: Sendable {
    func lookup(barcode: String) async throws -> ProductLookupResult?
}

protocol SmartScanServicing: Sendable {
    func detectItems(imageCount: Int) async throws -> [DetectedInventoryItem]
}

protocol ReceiptOCRServicing: Sendable {
    func parseReceipt() async throws -> [ReceiptLineItem]
}

protocol ExpiryOCRServicing: Sendable {
    func detectExpiry() async throws -> ExpiryDetection
}

protocol ProductSuggestionServicing: Sendable {
    func suggestions(from inventory: [InventoryItem], shoppingItems: [ShoppingListItem]) async -> [ShoppingListItem]
}

protocol NotificationManaging: Sendable {
    func requestAuthorization() async -> Bool
}

protocol HapticManaging: Sendable {
    func success()
    func selection()
}

enum ShelfServiceError: LocalizedError {
    case unavailable
    case notFound
    case cameraUnavailable
    case invalidInput
    case missingConfiguration

    var errorDescription: String? {
        switch self {
        case .unavailable: "The service is temporarily unavailable."
        case .notFound: "No matching product was found."
        case .cameraUnavailable: "Camera access is unavailable on this device."
        case .invalidInput: "The barcode is not valid."
        case .missingConfiguration: "AI features are not configured on this device."
        }
    }
}

struct UserNotificationManager: NotificationManaging {
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }
}

struct SystemHapticManager: HapticManaging {
    func success() {
        DispatchQueue.main.async {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func selection() {
        DispatchQueue.main.async {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
