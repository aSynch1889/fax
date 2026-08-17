import SwiftUI
import PencilKit

public struct SignaturePadView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var canvasView = PKCanvasView()
    public var onSave: (UIImage) -> Void
    
    public init(onSave: @escaping (UIImage) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("draw_signature_hint")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                PKCanvasRepresentable(canvasView: $canvasView)
                    .frame(height: 280)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: {
                        canvasView.drawing = PKDrawing()
                    }) {
                        Label("clear", systemImage: "trash")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        let image = renderSignature()
                        if let pngData = image.pngData() {
                            StorageManager.shared.saveSignature(data: pngData)
                        }
                        onSave(image)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("save", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.accent)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(Text("add_signature"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
    
    private func renderSignature() -> UIImage {
        let drawing = canvasView.drawing
        let bounds = drawing.bounds
        if bounds.isEmpty || bounds.width == 0 || bounds.height == 0 {
            return UIImage()
        }
        let image = drawing.image(from: bounds, scale: 2.0)
        return image
    }
}

public struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    public func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3.5)
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        return canvasView
    }
    
    public func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
