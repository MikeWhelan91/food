import Observation
import SwiftUI

@Observable
final class AppDependencies {
    let productLookup: ProductLookupServicing
    let smartScan: SmartScanServicing
    let receiptOCR: ReceiptOCRServicing
    let expiryOCR: ExpiryOCRServicing
    let suggestions: ProductSuggestionServicing
    let notifications: NotificationManaging
    let haptics: HapticManaging

    init(
        productLookup: ProductLookupServicing,
        smartScan: SmartScanServicing,
        receiptOCR: ReceiptOCRServicing,
        expiryOCR: ExpiryOCRServicing,
        suggestions: ProductSuggestionServicing,
        notifications: NotificationManaging,
        haptics: HapticManaging
    ) {
        self.productLookup = productLookup
        self.smartScan = smartScan
        self.receiptOCR = receiptOCR
        self.expiryOCR = expiryOCR
        self.suggestions = suggestions
        self.notifications = notifications
        self.haptics = haptics
    }

    static let live = AppDependencies(
        productLookup: OpenFoodFactsProductLookupService(),
        smartScan: OpenAISmartScanService(),
        receiptOCR: OpenAIReceiptOCRService(),
        expiryOCR: OpenAIExpiryOCRService(),
        suggestions: MockProductSuggestionService(),
        notifications: UserNotificationManager(),
        haptics: SystemHapticManager()
    )
}
