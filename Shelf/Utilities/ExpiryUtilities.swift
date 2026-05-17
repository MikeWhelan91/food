import Foundation
import SwiftUI

enum ExpiryUrgency: String, Codable, CaseIterable {
    case safe
    case soon
    case urgent
    case expired

    var label: String {
        switch self {
        case .safe: "Fresh"
        case .soon: "Soon"
        case .urgent: "Use now"
        case .expired: "Expired"
        }
    }

    var color: Color {
        switch self {
        case .safe: .shelfGreen
        case .soon: .shelfAmber
        case .urgent, .expired: .shelfRed
        }
    }
}

enum ExpiryFormatter {
    static func urgency(for date: Date?) -> ExpiryUrgency {
        guard let date else { return .safe }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days < 0 { return .expired }
        if days <= 1 { return .urgent }
        if days <= 5 { return .soon }
        return .safe
    }

    static func relativeText(for date: Date?) -> String {
        guard let date else { return "No expiry" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days < 0 { return "Expired \(abs(days))d ago" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        return "Expires in \(days)d"
    }
}
