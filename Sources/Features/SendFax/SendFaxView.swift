import SwiftUI
import PhotosUI
import PDFKit

public struct SendFaxView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var transmission = FaxTransmissionService.shared
    
    @State private var selectedCountry: Country = CountryManager.shared.defaultCountry
    @State private var faxNumber: String = ""
    @State private var recipientName: String = ""
    @State private var currentDocument: FaxDocument = FaxDocument()
    @State private var showingCountryPicker = false
    @State private var showingContacts = false
    @State private var showingCoverEditor = false
    @State private var showingDocumentEditor = false
    @State private var showingScanner = false
    @State private var showingPaywall = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    public init() {}
    
    private var totalPages: Int {
        return currentDocument.totalPagesCount
    }
    
    private var canSend: Bool {
        return !faxNumber.isEmpty && totalPages > 0 && !transmission.isTransmitting
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Transmission Progress banner
                    if transmission.isTransmitting {
                        VStack(spacing: 10) {
                            HStack {
                                Text(transmission.currentStepText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(Int(transmission.transmissionProgress * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: transmission.transmissionProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                        }
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                    }
                    
                    // 1. Recipient Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("recipient_section")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingContacts = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.circle")
                                    Text("choose_contact")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accent)
                            }
                        }
                        
                        // Country Selector
                        Button(action: { showingCountryPicker = true }) {
                            HStack {
                                Text(selectedCountry.flag)
                                    .font(.title3)
                                Text(selectedCountry.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedCountry.dialCode)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(12)
                        }
                        
                        // Fax Number Field
                        HStack {
                            Text(selectedCountry.dialCode)
                                .foregroundColor(.secondary)
                                .font(.body)
                            
                            TextField("fax_number_placeholder", text: $faxNumber)
                                .keyboardType(.phonePad)
                        }
                        .padding()
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(12)
                        
                        // Recipient Name (Optional)
                        TextField("recipient_name_placeholder", text: $recipientName)
                            .padding()
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(12)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // 2. Cover Page Card
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $currentDocument.coverPage.isEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("cover_page_section")
                                    .font(.headline)
                                Text(currentDocument.coverPage.template.localizedKey)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if currentDocument.coverPage.isEnabled {
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentDocument.coverPage.subject.isEmpty
                                         ? NSLocalizedString("cover_subject_none", comment: "")
                                         : String(format: NSLocalizedString("cover_subject_format", comment: ""), currentDocument.coverPage.subject))
                                        .font(.subheadline)
                                    Text(currentDocument.coverPage.senderName.isEmpty
                                         ? String(format: NSLocalizedString("from_format", comment: ""), NSLocalizedString("default_sender", comment: ""))
                                         : String(format: NSLocalizedString("from_format", comment: ""), currentDocument.coverPage.senderName))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: { showingCoverEditor = true }) {
                                    Text("edit_cover_page")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                        }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // 3. Document Pages Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("documents_section")
                                .font(.headline)
                            Spacer()
                            Text(String(format: NSLocalizedString("pages_count", comment: ""), currentDocument.pages.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if currentDocument.pages.isEmpty {
                            HStack(spacing: 12) {
                                Button(action: { showingScanner = true }) {
                                    Label("scan_document", systemImage: "camera.viewfinder")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppTheme.accent.opacity(0.12))
                                        .foregroundColor(AppTheme.accent)
                                        .cornerRadius(12)
                                }
                                
                                PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                                    Label("import_photos", systemImage: "photo")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.primary.opacity(0.05))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(currentDocument.pages.enumerated()), id: \.element.id) { idx, page in
                                        if let uiImage = storage.loadImage(named: page.imageFileName) {
                                            Image(uiImage: ImageFilterUtility.apply(filter: page.filter, to: uiImage))
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 110)
                                                .cornerRadius(8)
                                                .clipped()
                                                .overlay(
                                                    Text("\(idx + 1)")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding(4)
                                                        .background(Color.black.opacity(0.6))
                                                        .cornerRadius(4)
                                                        .padding(4),
                                                    alignment: .topLeading
                                                )
                                        }
                                    }
                                    
                                    Button(action: { showingScanner = true }) {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                            Text("add")
                                                .font(.caption)
                                        }
                                        .frame(width: 80, height: 110)
                                        .background(Color.primary.opacity(0.04))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            Button(action: { showingDocumentEditor = true }) {
                                HStack {
                                    Text("preview_edit_pages")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // 4. Action Button & Cost Info
                    VStack(spacing: 12) {
                        if totalPages > 0 {
                            Text(String(format: NSLocalizedString("credits_required", comment: ""), totalPages, totalPages))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            if !storage.hasActiveSubscription && storage.availableCredits < totalPages {
                                showingPaywall = true
                                return
                            }
                            
                            Task {
                                let recipient = FaxRecipient(
                                    name: recipientName,
                                    countryCode: selectedCountry.code,
                                    dialCode: selectedCountry.dialCode,
                                    faxNumber: faxNumber
                                )
                                
                                var images: [UIImage] = []
                                for p in currentDocument.pages {
                                    if let img = storage.loadImage(named: p.imageFileName) {
                                        images.append(img)
                                    }
                                }
                                
                                _ = await transmission.transmitFax(document: currentDocument, recipient: recipient, pageImages: images)
                            }
                        }) {
                            Text("send_fax_button")
                                .primaryButtonStyle(isEnabled: canSend)
                        }
                        .disabled(!canSend)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
            }
            .navigationTitle(Text("send_fax_title"))
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(selectedCountry: $selectedCountry)
            }
            .sheet(isPresented: $showingContacts) {
                NavigationView {
                    ContactsListView { contact in
                        self.recipientName = contact.name
                        self.faxNumber = contact.faxNumber
                        if let c = CountryManager.shared.findCountry(by: contact.countryCode) {
                            self.selectedCountry = c
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCoverEditor) {
                CoverPageEditorView(coverData: $currentDocument.coverPage)
            }
            .sheet(isPresented: $showingDocumentEditor) {
                NavigationView {
                    DocumentEditorView(document: $currentDocument)
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerRepresentable(onScanned: { images in
                    for img in images {
                        let fn = storage.savePageImage(img)
                        currentDocument.pages.append(FaxPage(imageFileName: fn))
                    }
                }, onCancel: {})
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            let fn = storage.savePageImage(img)
                            currentDocument.pages.append(FaxPage(imageFileName: fn))
                        }
                    }
                    selectedPhotoItems.removeAll()
                }
            }
        }
    }
}

public struct DocumentsListView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var showingScanner = false
    @State private var selectedDoc: FaxDocument?
    
    public var body: some View {
        NavigationView {
            List {
                if storage.documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("no_documents_title")
                            .font(.headline)
                        Text("no_documents_desc")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(storage.documents) { doc in
                        NavigationLink(destination: DocumentEditorView(document: binding(for: doc))) {
                            HStack(spacing: 14) {
                                Image(systemName: "doc.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(doc.title)
                                        .font(.headline)
                                    Text(String(format: NSLocalizedString("pages_count_date", comment: ""), doc.pages.count, DateFormatter.localizedString(from: doc.updatedAt, dateStyle: .short, timeStyle: .none)))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            let doc = storage.documents[idx]
                            storage.deleteDocument(id: doc.id)
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_documents"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingScanner = true }) {
                        Image(systemName: "camera.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerRepresentable(onScanned: { images in
                    var newDoc = FaxDocument(title: String(format: NSLocalizedString("scanned_doc_title", comment: ""), DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)))
                    for img in images {
                        let fn = storage.savePageImage(img)
                        newDoc.pages.append(FaxPage(imageFileName: fn))
                    }
                    storage.saveDocument(newDoc)
                }, onCancel: {})
            }
        }
    }
    
    private func binding(for doc: FaxDocument) -> Binding<FaxDocument> {
        Binding(
            get: {
                storage.documents.first(where: { $0.id == doc.id }) ?? doc
            },
            set: { updated in
                storage.saveDocument(updated)
            }
        )
    }
}
