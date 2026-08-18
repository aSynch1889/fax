import SwiftUI
import PhotosUI

public struct DocumentEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding public var document: FaxDocument
    @ObservedObject var storage = StorageManager.shared
    
    @State private var selectedPageIndex: Int = 0
    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingSignaturePad = false
    @State private var showingCoverEditor = false
    
    public init(document: Binding<FaxDocument>) {
        self._document = document
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Preview Carousel / Grid
            if document.pages.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppTheme.accent)
                    
                    Text("no_pages_title")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button(action: { showingScanner = true }) {
                            Label("scan_document", systemImage: "camera.viewfinder")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppTheme.accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                            Label("import_photos", systemImage: "photo.on.rectangle")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppTheme.secondaryGroupBackground)
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $selectedPageIndex) {
                    ForEach(Array(document.pages.enumerated()), id: \.element.id) { index, page in
                        PageDetailCard(page: page, pageNumber: index + 1, totalPages: document.pages.count)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: .infinity)
                
                // Toolbar for current page
                if selectedPageIndex < document.pages.count {
                    HStack(spacing: 24) {
                        // Rotate
                        Button(action: {
                            var p = document.pages[selectedPageIndex]
                            p.rotationAngle = (p.rotationAngle + 90).truncatingRemainder(dividingBy: 360)
                            document.pages[selectedPageIndex] = p
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "rotate.right")
                                Text("rotate")
                                    .font(.caption2)
                            }
                        }
                        
                        // Filters menu
                        Menu {
                            ForEach(FilterType.allCases) { f in
                                Button(action: {
                                    document.pages[selectedPageIndex].filter = f
                                }) {
                                    HStack {
                                        Text(f.localizedKey)
                                        if document.pages[selectedPageIndex].filter == f {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "camera.filters")
                                Text("filter")
                                    .font(.caption2)
                            }
                        }
                        
                        // Add Signature
                        Button(action: { showingSignaturePad = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "signature")
                                Text("sign_document")
                                    .font(.caption2)
                            }
                        }
                        
                        // Delete Page
                        Button(action: {
                            let p = document.pages[selectedPageIndex]
                            storage.deleteImage(named: p.imageFileName)
                            document.pages.remove(at: selectedPageIndex)
                            if selectedPageIndex > 0 {
                                selectedPageIndex -= 1
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("delete")
                                    .font(.caption2)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .font(.title3)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.secondaryGroupBackground)
                }
            }
        }
        .navigationTitle(document.title.isEmpty ? NSLocalizedString("edit_document", comment: "") : document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingScanner = true }) {
                        Label("scan_document", systemImage: "camera.viewfinder")
                    }
                    PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                        Label("import_photos", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerRepresentable(onScanned: { images in
                for img in images {
                    let fn = storage.savePageImage(img)
                    document.pages.append(FaxPage(imageFileName: fn))
                }
            }, onCancel: {})
        }
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadView(onSave: { sigImg in
                if let png = sigImg.pngData(), selectedPageIndex < document.pages.count {
                    let sigPlacement = SignaturePlacement(relativeX: 0.5, relativeY: 0.75, relativeWidth: 0.4, signatureImageData: png)
                    document.pages[selectedPageIndex].signatures.append(sigPlacement)
                }
            })
        }
        .onChange(of: selectedPhotoItems) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        let fn = storage.savePageImage(img)
                        document.pages.append(FaxPage(imageFileName: fn))
                    }
                }
                selectedPhotoItems.removeAll()
            }
        }
    }
}

public struct PageDetailCard: View {
    public var page: FaxPage
    public var pageNumber: Int
    public var totalPages: Int
    
    var loadedImage: UIImage? {
        if let raw = StorageManager.shared.loadImage(named: page.imageFileName) {
            return ImageFilterUtility.apply(filter: page.filter, to: raw)
        }
        return nil
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Text(String(format: NSLocalizedString("page_x_of_y", comment: ""), pageNumber, totalPages))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let image = loadedImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(page.rotationAngle))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    
                    // Render signatures
                    ForEach(page.signatures) { sig in
                        if let sigImg = UIImage(data: sig.signatureImageData) {
                            Image(uiImage: sigImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140)
                                .position(x: 200, y: 350)
                        }
                    }
                }
                .padding()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(ProgressView())
                    .padding()
            }
        }
    }
}
