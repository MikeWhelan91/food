import AVFoundation
import SwiftData
import SwiftUI
import VisionKit

enum ScanRoute: Hashable {
    case barcode
    case smart
    case receipt
    case manual
}

struct ScanHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: ScanRoute.barcode) {
                        ScanActionRow(symbol: "barcode.viewfinder", title: "Barcode Scan", message: "Scan a product barcode")
                    }
                    NavigationLink(value: ScanRoute.smart) {
                        ScanActionRow(symbol: "camera.viewfinder", title: "Smart Scan", message: "Scan your fridge or pantry")
                    }
                    NavigationLink(value: ScanRoute.receipt) {
                        ScanActionRow(symbol: "doc.text.viewfinder", title: "Receipt Scan", message: "Import from a receipt")
                    }
                    NavigationLink(value: ScanRoute.manual) {
                        ScanActionRow(symbol: "pencil", title: "Manual Entry", message: "Add item manually")
                    }
                } header: {
                    Text("Add items quickly using any method")
                        .textCase(nil)
                }
            }
            .navigationTitle("Scan")
            .navigationDestination(for: ScanRoute.self) { route in
                switch route {
                case .barcode: BarcodeScanFlow()
                case .smart: SmartScanFlow()
                case .receipt: ReceiptScanFlow()
                case .manual: ItemEditView(mode: .add)
                }
            }
        }
    }
}

private struct ScanActionRow: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: ShelfSpacing.md) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.shelfGreen)
                .frame(width: 34, height: 34)
                .background(Color.shelfGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
            .lineLimit(nil)
        }
        .padding(.vertical, 6)
    }
}

struct BarcodeScanFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @State private var state: Loadable<ProductLookupResult> = .idle
    @State private var barcode = "5010255079763"

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            CameraPreviewPlaceholder(title: "Scan a barcode", symbol: "barcode.viewfinder")
            switch state {
            case .idle:
                VStack(spacing: ShelfSpacing.sm) {
                    TextField("Barcode", text: $barcode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button("Simulate Scan", action: lookup)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            case .loading:
                LoadingStateView(title: "Looking up product", message: "Checking local cache and product databases.")
            case let .loaded(result):
                ProductConfirmationCard(result: result, add: { add(result) })
            case let .failed(message):
                ErrorRecoveryView(message: message, retry: lookup)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Barcode")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lookup() {
        state = .loading
        Task {
            do {
                if let result = try await dependencies.productLookup.lookup(barcode: barcode) {
                    state = .loaded(result)
                } else {
                    state = .failed("No product was found. You can create it manually.")
                }
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func add(_ result: ProductLookupResult) {
        let item = InventoryItem(productName: result.name, brand: result.brand, category: result.category, locationName: result.category.rawValue, imageSystemName: result.imageSystemName, expiry: ExpiryInfo(date: .daysFromNow(7), label: "Best Before", confidence: result.confidence, source: result.source), events: [InventoryEvent(kind: .added, message: "Added from barcode")])
        modelContext.insert(item)
        dependencies.haptics.success()
    }
}

struct SmartScanFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @State private var imageCount = 1
    @State private var detections: [DetectedInventoryItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            CameraPreviewPlaceholder(title: "Smart Scan", symbol: "camera.viewfinder")
            Stepper("Images: \(imageCount)", value: $imageCount, in: 1...3)
                .padding(.horizontal)
            if isProcessing {
                LoadingStateView(title: "Detecting items", message: "Review every result before anything is added.")
            } else if let errorMessage {
                ErrorRecoveryView(message: errorMessage, retry: process)
            } else if detections.isEmpty {
                Button("Capture and Detect", action: process)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            } else {
                DetectionConfirmationList(detections: $detections, addAll: addAll)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Smart Scan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func process() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                detections = try await dependencies.smartScan.detectItems(imageCount: imageCount)
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    private func addAll() {
        detections.forEach { detection in
            modelContext.insert(InventoryItem(productName: detection.name, brand: detection.brand, quantity: detection.quantity, category: detection.category, locationName: detection.category.rawValue, imageSystemName: detection.imageSystemName, expiry: ExpiryInfo(date: detection.expiryDate, label: "Best Before", confidence: detection.confidence, source: "Smart Scan"), events: [InventoryEvent(kind: .added, message: "Added from smart scan")]))
        }
        detections.removeAll()
        dependencies.haptics.success()
    }
}

struct ReceiptScanFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @State private var state: Loadable<[ReceiptLineItem]> = .idle

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            CameraPreviewPlaceholder(title: "Receipt Scan", symbol: "doc.text.viewfinder")
            switch state {
            case .idle:
                Button("Scan Receipt", action: parse)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            case .loading:
                LoadingStateView(title: "Reading receipt", message: "Extracting products and quantities.")
            case let .loaded(items):
                ReceiptConfirmationList(items: Binding(get: { items }, set: { state = .loaded($0) }), addAll: addAll)
            case let .failed(message):
                ErrorRecoveryView(message: message, retry: parse)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func parse() {
        state = .loading
        Task {
            do {
                state = .loaded(try await dependencies.receiptOCR.parseReceipt())
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func addAll(_ items: [ReceiptLineItem]) {
        items.forEach { line in
            modelContext.insert(InventoryItem(productName: line.name, quantity: line.quantity, category: line.category, locationName: line.category.rawValue, imageSystemName: line.category.symbol, expiry: ExpiryInfo(date: .daysFromNow(7), label: "Best Before", confidence: line.confidence, source: "Receipt"), events: [InventoryEvent(kind: .added, message: "Added from receipt")]))
        }
        dependencies.haptics.success()
        state = .idle
    }
}

enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

private struct CameraPreviewPlaceholder: View {
    let title: String
    let symbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .aspectRatio(1.18, contentMode: .fit)
            VStack(spacing: ShelfSpacing.sm) {
                Image(systemName: symbol)
                    .font(.system(size: 46))
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1)
                .padding(34)
        }
        .accessibilityLabel(title)
    }
}

private struct ProductConfirmationCard: View {
    let result: ProductLookupResult
    let add: () -> Void

    var body: some View {
        VStack(spacing: ShelfSpacing.md) {
            HStack(spacing: ShelfSpacing.md) {
                ProductThumbnail(systemName: result.imageSystemName, category: result.category, size: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.name).font(.headline)
                    Text(result.brand.isEmpty ? result.source : result.brand)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(result.confidence * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Button("Add to Inventory", action: add)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
        .shelfSurface(radius: 18)
    }
}

private struct DetectionConfirmationList: View {
    @Binding var detections: [DetectedInventoryItem]
    let addAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.md) {
            Text("Detected Items").font(.headline)
            VStack(spacing: 0) {
                ForEach($detections) { $item in
                    HStack(spacing: ShelfSpacing.sm) {
                        ProductThumbnail(systemName: item.imageSystemName, category: item.category, size: 36)
                        TextField("Name", text: $item.name)
                            .font(.subheadline.weight(.medium))
                        Stepper("\(item.quantity.formatted())", value: $item.quantity, in: 0...20, step: 1)
                            .labelsHidden()
                    }
                    .padding(.vertical, 7)
                }
                .onDelete { detections.remove(atOffsets: $0) }
            }
            Button("Add \(detections.count) Items", action: addAll)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(detections.isEmpty)
        }
        .shelfSurface(radius: 18)
    }
}

private struct ReceiptConfirmationList: View {
    @Binding var items: [ReceiptLineItem]
    let addAll: ([ReceiptLineItem]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ShelfSpacing.md) {
            Text("Extracted Items").font(.headline)
            ForEach($items) { $item in
                HStack {
                    TextField("Item", text: $item.name)
                    Stepper("\(item.quantity.formatted())", value: $item.quantity, in: 0...20, step: 1)
                        .labelsHidden()
                    Picker("Category", selection: $item.category) {
                        ForEach(CategoryKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                }
                .font(.subheadline)
            }
            Button("Add \(items.count) Items") { addAll(items) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
        .shelfSurface(radius: 18)
    }
}
