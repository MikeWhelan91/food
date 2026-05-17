import SwiftUI

extension Color {
    static let shelfGreen = Color(red: 0.24, green: 0.34, blue: 0.26)
    static let shelfAmber = Color(red: 0.76, green: 0.48, blue: 0.17)
    static let shelfRed = Color(red: 0.72, green: 0.19, blue: 0.16)
    static let shelfBlue = Color(red: 0.18, green: 0.36, blue: 0.57)
    static let shelfCanvas = Color(red: 0.96, green: 0.95, blue: 0.91)
    static let shelfGrouped = Color(red: 0.99, green: 0.98, blue: 0.95)
}

enum ShelfSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
}

struct ShelfSurface: ViewModifier {
    var radius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(ShelfSpacing.md)
            .background(Color.shelfGrouped, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func shelfSurface(radius: CGFloat = 16) -> some View {
        modifier(ShelfSurface(radius: radius))
    }
}

extension Date {
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }
}
