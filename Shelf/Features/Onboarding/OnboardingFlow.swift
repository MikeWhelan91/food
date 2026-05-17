import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    let complete: () -> Void
    @State private var page = 0
    @State private var notificationStatus = "Not enabled"

    var body: some View {
        TabView(selection: $page) {
            OnboardingPage(title: "Know what's in your home.", message: "Track expiry dates, reduce waste, and shop smarter.", symbol: "shippingbox", primaryTitle: "Get Started", secondaryTitle: "Skip", primary: next, secondary: complete)
                .tag(0)
            OnboardingFeaturesPage(primary: next, secondary: complete)
                .tag(1)
            OnboardingPage(title: "Stay ahead of expiries", message: "Shelf can remind you before items expire so you can use them in time.", symbol: "bell.badge", primaryTitle: "Enable Notifications", secondaryTitle: "Skip", primary: requestNotifications, secondary: next)
                .tag(2)
            OnboardingPage(title: "Secure and private", message: "Your data stays in your control. Sign in only syncs across your devices.", symbol: "lock.shield", primaryTitle: "Sign in with Apple", secondaryTitle: "Continue without account", primary: complete, secondary: complete)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color(.systemGroupedBackground))
    }

    private func next() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            page = min(page + 1, 3)
        }
    }

    private func requestNotifications() {
        Task {
            let granted = await dependencies.notifications.requestAuthorization()
            notificationStatus = granted ? "Enabled" : "Not enabled"
            next()
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let message: String
    let symbol: String
    let primaryTitle: String
    let secondaryTitle: String
    let primary: () -> Void
    let secondary: () -> Void

    var body: some View {
        VStack(spacing: ShelfSpacing.xl) {
            Spacer(minLength: ShelfSpacing.lg)
            Image(systemName: symbol)
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Color.shelfGreen)
                .frame(width: 96, height: 96)
                .background(Color.shelfGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            VStack(spacing: ShelfSpacing.sm) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, ShelfSpacing.xl)
            Spacer()
            VStack(spacing: ShelfSpacing.sm) {
                Button(primaryTitle, action: primary)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                Button(secondaryTitle, action: secondary)
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, ShelfSpacing.xl)
            .padding(.bottom, ShelfSpacing.xl)
        }
        .tint(.shelfGreen)
    }
}

private struct OnboardingFeaturesPage: View {
    let primary: () -> Void
    let secondary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.xl) {
            Spacer(minLength: ShelfSpacing.lg)
            VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                Text("Everything in one place")
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(nil)
                Text("Add items quickly and keep the household inventory current.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: ShelfSpacing.lg) {
                FeatureRow(symbol: "barcode.viewfinder", title: "Scan barcodes", message: "Add items in seconds")
                FeatureRow(symbol: "camera.viewfinder", title: "Smart scan", message: "Detect items in your fridge or pantry")
                FeatureRow(symbol: "bell.badge", title: "Expiry alerts", message: "Never miss an expiry date")
            }
            Spacer()
            VStack(spacing: ShelfSpacing.sm) {
                Button("Next", action: primary)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                Button("Skip", action: secondary)
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(.horizontal, ShelfSpacing.xl)
        .padding(.bottom, ShelfSpacing.xl)
        .tint(.shelfGreen)
    }
}

private struct FeatureRow: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: ShelfSpacing.md) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.shelfGreen)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
