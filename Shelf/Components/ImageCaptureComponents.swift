import SwiftUI
import UIKit

struct CapturedImage: Identifiable, Hashable {
    let id = UUID()
    var image: UIImage

    var payload: ScanImagePayload? {
        image.resizedForUpload(maxDimension: 1200)
            .jpegData(compressionQuality: 0.72)
            .map { ScanImagePayload(base64: $0.base64EncodedString(), mimeType: "image/jpeg") }
    }
}

struct ImageCaptureButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isDisabled)
    }
}

struct CapturedImagesStrip: View {
    let images: [CapturedImage]
    let remove: (CapturedImage) -> Void

    var body: some View {
        if !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ShelfSpacing.sm) {
                    ForEach(images) { captured in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: captured.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            Button {
                                remove(captured)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            .padding(5)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollClipDisabled()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImage: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImage: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImage = onImage
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private extension UIImage {
    func resizedForUpload(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
