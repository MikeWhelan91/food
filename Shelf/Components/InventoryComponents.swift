import SwiftUI

struct ExpiryPill: View {
    let date: Date?

    var body: some View {
        let urgency = ExpiryFormatter.urgency(for: date)
        Text(ExpiryFormatter.relativeText(for: date))
            .font(.caption.weight(.semibold))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .foregroundStyle(urgency.color)
            .background(urgency.color.opacity(0.13), in: Capsule())
            .accessibilityLabel("\(urgency.label), \(ExpiryFormatter.relativeText(for: date))")
    }
}

struct ProductThumbnail: View {
    let systemName: String
    let category: CategoryKind
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(categoryColor.opacity(0.14))
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(categoryColor)
                .imageScale(.medium)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var categoryColor: Color {
        switch category {
        case .fridge: .shelfBlue
        case .freezer: .cyan
        case .pantry: .shelfGreen
        case .bathroom: .indigo
        case .cleaning: .teal
        case .pet: .brown
        }
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    var compact = false

    var body: some View {
        HStack(alignment: .center, spacing: ShelfSpacing.md) {
            ProductThumbnail(systemName: item.imageSystemName, category: item.category, size: compact ? 40 : 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.productName)
                        .font(.body.weight(.semibold))
                        .lineLimit(nil)
                    Spacer(minLength: ShelfSpacing.sm)
                    Text(quantityText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: ShelfSpacing.xs) {
                    Text(item.locationName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                    Spacer(minLength: ShelfSpacing.sm)
                    ExpiryPill(date: item.expiry?.date)
                }
            }
        }
        .padding(.vertical, compact ? 6 : 9)
        .contentShape(Rectangle())
    }

    private var quantityText: String {
        if item.quantity.rounded() == item.quantity {
            return "\(Int(item.quantity)) \(item.unit.rawValue)"
        }
        return "\(item.quantity.formatted()) \(item.unit.rawValue)"
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.shelfGreen)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: ShelfSpacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.secondary)
            VStack(spacing: ShelfSpacing.xs) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(ShelfSpacing.xl)
        .frame(maxWidth: 360)
        .accessibilityElement(children: .contain)
    }
}

struct SkeletonRowsView: View {
    var body: some View {
        VStack(spacing: ShelfSpacing.md) {
            ForEach(0..<4, id: \.self) { index in
                HStack(spacing: ShelfSpacing.md) {
                    RoundedRectangle(cornerRadius: 12).fill(.quaternary).frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(.quaternary).frame(width: index.isMultiple(of: 2) ? 160 : 120, height: 12)
                        RoundedRectangle(cornerRadius: 4).fill(.quaternary).frame(width: 210, height: 10)
                    }
                    Spacer()
                }
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading")
    }
}
