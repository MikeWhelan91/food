import SwiftUI

struct CategoryPickerChips: View {
    @Binding var selection: CategoryKind?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ShelfSpacing.sm) {
                chip(title: "All", symbol: "square.grid.2x2", isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(CategoryKind.allCases) { category in
                    chip(title: category.rawValue, symbol: category.symbol, isSelected: selection == category) {
                        selection = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }

    private func chip(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.shelfGreen : Color.shelfGrouped, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct LoadingStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            ProgressView()
                .controlSize(.large)
            VStack(spacing: ShelfSpacing.xs) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(ShelfSpacing.xl)
        .frame(maxWidth: 340)
    }
}

struct ErrorRecoveryView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: ShelfSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.shelfAmber)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(ShelfSpacing.xl)
    }
}
