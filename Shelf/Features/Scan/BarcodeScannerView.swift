import AVFoundation
import SwiftUI

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        BarcodeScannerViewController(onCode: onCode, onError: onError)
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let onCode: (String) -> Void
    private let onError: (String) -> Void
    private var didEmitCode = false

    init(onCode: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        self.onCode = onCode
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didEmitCode = false
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            onError("Camera is unavailable.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                onError("Camera input could not be configured.")
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                onError("Barcode scanning could not be configured.")
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = output.availableMetadataObjectTypes.filter {
                [.ean13, .ean8, .upce, .qr, .dataMatrix, .code128, .code39, .pdf417].contains($0)
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        } catch {
            onError("Camera permission is needed to scan barcodes.")
        }
    }

    private func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didEmitCode,
              let object = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let value = object.stringValue
        else {
            return
        }

        didEmitCode = true
        session.stopRunning()
        onCode(value)
    }
}
