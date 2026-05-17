import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @AppStorage("userName") private var storedName = ""
    let complete: () -> Void

    @State private var name = ""
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                NameSetupPage(name: $name, continueAction: next)
                    .tag(0)
                CapabilitySetupPage(continueAction: next)
                    .tag(1)
                NotificationSetupPage(
                    enable: requestNotifications,
                    skip: finish
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .background(Color.shelfCanvas.ignoresSafeArea())
        .onAppear {
            name = storedName
        }
    }

    private func next() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            page = min(page + 1, 2)
        }
    }

    private func finish() {
        storedName = cleanedName
        complete()
    }

    private func requestNotifications() {
        Task {
            _ = await dependencies.notifications.requestAuthorization()
            await MainActor.run {
                finish()
            }
        }
    }

    private var cleanedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "there" : trimmed
    }
}

private struct NameSetupPage: View {
    @Binding var name: String
    let continueAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.xl) {
            Spacer(minLength: 48)

            VStack(alignment: .leading, spacing: ShelfSpacing.md) {
                Text("Shelf")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.shelfGreen)
                Text("Know what's in your home.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Start with your name. Shelf uses it only to make the app feel personal.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                Text("Your name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Mike", text: $name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, ShelfSpacing.md)
                    .frame(minHeight: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
                    .onSubmit(continueAction)
            }

            Spacer()

            Button("Continue", action: continueAction)
                .buttonStyle(ShelfPrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 54)
    }
}

private struct CapabilitySetupPage: View {
    let continueAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.xl) {
            Spacer(minLength: 54)

            VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                Text("Add items quickly")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Barcode, shelf photos, receipts, and manual entry all lead to the same clean inventory.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: ShelfSpacing.md) {
                SetupRow(symbol: "barcode.viewfinder", title: "Barcode scan", detail: "Product lookup with images when available")
                SetupRow(symbol: "camera.viewfinder", title: "Smart scan", detail: "Review detected items before adding")
                SetupRow(symbol: "calendar.badge.clock", title: "Expiry tracking", detail: "Keep soon and urgent items visible")
            }

            Spacer()

            Button("Continue", action: continueAction)
                .buttonStyle(ShelfPrimaryButtonStyle())
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 54)
    }
}

private struct NotificationSetupPage: View {
    let enable: () -> Void
    let skip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.xl) {
            Spacer(minLength: 54)

            Image(systemName: "bell.badge")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(Color.shelfGreen)
                .frame(width: 74, height: 74)
                .background(Color.shelfGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: ShelfSpacing.sm) {
                Text("Expiry reminders")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Shelf can remind you before food expires. You can change this later in Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: ShelfSpacing.sm) {
                Button("Enable Notifications", action: enable)
                    .buttonStyle(ShelfPrimaryButtonStyle())
                Button("Not Now", action: skip)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.shelfGreen)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 54)
    }
}

private struct SetupRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: ShelfSpacing.md) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.shelfGreen)
                .frame(width: 38, height: 38)
                .background(Color.shelfGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ShelfPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.shelfGreen.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
