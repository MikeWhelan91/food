import AVFoundation
import SwiftData
import SwiftUI
import UIKit
import VisionKit

enum ScanRoute: Hashable {
    case barcode
    case smart
    case receipt
    case manual
}

struct ScanHubView: View {
    @Binding var selectedTab: AppTab
    @State private var path: [ScanRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
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
                case .barcode: BarcodeScanFlow(selectedTab: $selectedTab, path: $path)
                case .smart: SmartScanFlow(selectedTab: $selectedTab, path: $path)
                case .receipt: ReceiptScanFlow(selectedTab: $selectedTab, path: $path)
                case .manual: ItemEditView(mode: .add) {
                    path.removeAll()
                    selectedTab = .inventory
                }
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
    @Binding var selectedTab: AppTab
    @Binding var path: [ScanRoute]
    @State private var state: Loadable<ProductLookupResult> = .idle
    @State private var barcode = ""
    @State private var scannerError: String?

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            ZStack(alignment: .bottom) {
                BarcodeScannerView(
                    onCode: handleScannedCode,
                    onError: { scannerError = $0 }
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1.08, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                BarcodeScannerOverlay()
            }

            if let scannerError {
                Text(scannerError)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            switch state {
            case .idle:
                VStack(spacing: ShelfSpacing.sm) {
                    TextField("Barcode", text: $barcode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button("Look Up Barcode", action: lookup)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func handleScannedCode(_ code: String) {
        barcode = code
        lookup()
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
        let item = InventoryItem(productName: result.name, brand: result.brand, category: result.category, locationName: result.category.rawValue, imageSystemName: result.imageSystemName, imageURLString: result.imageURL?.absoluteString, expiry: ExpiryInfo(date: .daysFromNow(7), label: "Best Before", confidence: result.confidence, source: result.source), events: [InventoryEvent(kind: .added, message: "Added from barcode")])
        modelContext.insert(item)
        dependencies.haptics.success()
        path.removeAll()
        selectedTab = .inventory
    }
}

struct SmartScanFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: AppTab
    @Binding var path: [ScanRoute]
    @State private var capturedImages: [CapturedImage] = []
    @State private var detections: [DetectedInventoryItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingCamera = false

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            CameraPreviewPlaceholder(title: "Smart Scan", symbol: "camera.viewfinder")
            CapturedImagesStrip(images: capturedImages) { captured in
                capturedImages.removeAll { $0.id == captured.id }
            }

            if isProcessing {
                LoadingStateView(title: "Detecting items", message: "Review every result before anything is added.")
            } else if let errorMessage {
                ErrorRecoveryView(message: errorMessage, retry: process)
            } else if detections.isEmpty {
                VStack(spacing: ShelfSpacing.sm) {
                    ImageCaptureButton(
                        title: capturedImages.isEmpty ? "Capture Shelf" : "Capture Another",
                        systemImage: "camera",
                        isDisabled: capturedImages.count >= 3
                    ) {
                        showingCamera = true
                    }
                    Button("Detect Items", action: process)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(capturedImages.isEmpty)
                }
            } else {
                DetectionConfirmationList(detections: $detections, addAll: addAll)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Smart Scan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                capturedImages.append(CapturedImage(image: image))
            }
            .ignoresSafeArea()
        }
    }

    private func process() {
        let payloads = capturedImages.compactMap(\.payload)
        guard !payloads.isEmpty else {
            errorMessage = "Capture at least one image before detecting items."
            return
        }

        isProcessing = true
        errorMessage = nil
        Task {
            do {
                detections = try await dependencies.smartScan.detectItems(images: payloads)
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
        path.removeAll()
        selectedTab = .inventory
    }
}

struct ReceiptScanFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: AppTab
    @Binding var path: [ScanRoute]
    @State private var state: Loadable<[ReceiptLineItem]> = .idle
    @State private var capturedImage: CapturedImage?
    @State private var showingCamera = false

    var body: some View {
        VStack(spacing: ShelfSpacing.lg) {
            if let capturedImage {
                Image(uiImage: capturedImage.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.78, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                CameraPreviewPlaceholder(title: "Receipt Scan", symbol: "doc.text.viewfinder")
            }

            switch state {
            case .idle:
                VStack(spacing: ShelfSpacing.sm) {
                    ImageCaptureButton(
                        title: capturedImage == nil ? "Capture Receipt" : "Retake Receipt",
                        systemImage: "camera",
                        isDisabled: false
                    ) {
                        showingCamera = true
                    }
                    Button("Extract Items", action: parse)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(capturedImage == nil)
                }
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
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                capturedImage = CapturedImage(image: image)
                state = .idle
            }
            .ignoresSafeArea()
        }
    }

    private func parse() {
        guard let payload = capturedImage?.payload else {
            state = .failed("Capture a receipt before extracting items.")
            return
        }

        state = .loading
        Task {
            do {
                state = .loaded(try await dependencies.receiptOCR.parseReceipt(image: payload))
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
        path.removeAll()
        selectedTab = .inventory
    }
}

private struct BarcodeScannerOverlay: View {
    var body: some View {
        VStack(spacing: ShelfSpacing.md) {
            Spacer()
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.82), lineWidth: 2)
                .frame(width: 250, height: 142)
                .overlay(alignment: .bottom) {
                    Text("Align barcode inside the frame")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.48), in: Capsule())
                        .offset(y: 24)
                }
            Spacer()
        }
        .padding()
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
                ProductThumbnail(systemName: result.imageSystemName, category: result.category, size: 58, imageURLString: result.imageURL?.absoluteString)
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
