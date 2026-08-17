import SwiftUI
import VisionKit

public struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    public var onScanned: ([UIImage]) -> Void
    public var onCancel: () -> Void
    
    public init(onScanned: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
        self.onScanned = onScanned
        self.onCancel = onCancel
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerRepresentable
        
        init(_ parent: DocumentScannerRepresentable) {
            self.parent = parent
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.onScanned(images)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel()
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
