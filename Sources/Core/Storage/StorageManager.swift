import Foundation
import UIKit

@MainActor
public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()
    
    @Published public var documents: [FaxDocument] = []
    @Published public var contacts: [FaxRecipient] = []
    @Published public var historyRecords: [FaxTransmissionRecord] = []
    @Published public var savedSignatures: [Data] = []
    @Published public var availableCredits: Int = 5 // Free starter credits
    @Published public var hasActiveSubscription: Bool = false
    
    private let documentsURL: URL
    private let imagesDirectoryURL: URL
    private let contactsURL: URL
    private let historyURL: URL
    private let signaturesURL: URL
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let baseDir = appSupport.appendingPathComponent("FaxFlowData", isDirectory: true)
        try? fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
        
        self.documentsURL = baseDir.appendingPathComponent("documents.json")
        self.imagesDirectoryURL = baseDir.appendingPathComponent("PageImages", isDirectory: true)
        self.contactsURL = baseDir.appendingPathComponent("contacts.json")
        self.historyURL = baseDir.appendingPathComponent("history.json")
        self.signaturesURL = baseDir.appendingPathComponent("signatures.json")
        
        try? fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
        
        loadAll()
        
        #if SCREENSHOT_MODE
        populateMockDataIfEmpty()
        #endif
    }
    
    // MARK: - Persistence
    public func loadAll() {
        loadDocuments()
        loadContacts()
        loadHistory()
        loadSignatures()
        self.availableCredits = UserDefaults.standard.integer(forKey: "UserFaxCredits")
        if self.availableCredits == 0 && !UserDefaults.standard.bool(forKey: "InitializedCredits") {
            self.availableCredits = 5
            UserDefaults.standard.set(true, forKey: "InitializedCredits")
            UserDefaults.standard.set(5, forKey: "UserFaxCredits")
        }
        self.hasActiveSubscription = UserDefaults.standard.bool(forKey: "HasActiveSubscription")
    }
    
    public func addCredits(_ amount: Int) {
        self.availableCredits += amount
        UserDefaults.standard.set(self.availableCredits, forKey: "UserFaxCredits")
    }
    
    public func deductCredits(_ amount: Int) -> Bool {
        if hasActiveSubscription { return true }
        guard availableCredits >= amount else { return false }
        availableCredits -= amount
        UserDefaults.standard.set(availableCredits, forKey: "UserFaxCredits")
        return true
    }
    
    public func setSubscriptionActive(_ active: Bool) {
        self.hasActiveSubscription = active
        UserDefaults.standard.set(active, forKey: "HasActiveSubscription")
    }
    
    // MARK: - Documents
    public func saveDocument(_ doc: FaxDocument) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx] = doc
        } else {
            documents.insert(doc, at: 0)
        }
        persistDocuments()
    }
    
    public func deleteDocument(id: UUID) {
        if let doc = documents.first(where: { $0.id == id }) {
            for page in doc.pages {
                deleteImage(named: page.imageFileName)
            }
        }
        documents.removeAll(where: { $0.id == id })
        persistDocuments()
    }
    
    private func persistDocuments() {
        if let data = try? JSONEncoder().encode(documents) {
            try? data.write(to: documentsURL, options: .atomic)
        }
    }
    
    private func loadDocuments() {
        guard let data = try? Data(contentsOf: documentsURL),
              let loaded = try? JSONDecoder().decode([FaxDocument].self, from: data) else {
            return
        }
        self.documents = loaded
    }
    
    // MARK: - Images
    public func savePageImage(_ image: UIImage) -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: fileURL, options: .atomic)
        }
        return fileName
    }
    
    public func loadImage(named fileName: String) -> UIImage? {
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    public func deleteImage(named fileName: String) {
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Contacts
    public func saveContact(_ contact: FaxRecipient) {
        if let idx = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[idx] = contact
        } else {
            contacts.append(contact)
        }
        persistContacts()
    }
    
    public func deleteContact(id: UUID) {
        contacts.removeAll(where: { $0.id == id })
        persistContacts()
    }
    
    private func persistContacts() {
        if let data = try? JSONEncoder().encode(contacts) {
            try? data.write(to: contactsURL, options: .atomic)
        }
    }
    
    private func loadContacts() {
        guard let data = try? Data(contentsOf: contactsURL),
              let loaded = try? JSONDecoder().decode([FaxRecipient].self, from: data) else {
            return
        }
        self.contacts = loaded
    }
    
    // MARK: - History
    public func addHistoryRecord(_ record: FaxTransmissionRecord) {
        historyRecords.insert(record, at: 0)
        persistHistory()
    }
    
    public func updateHistoryRecord(_ record: FaxTransmissionRecord) {
        if let idx = historyRecords.firstIndex(where: { $0.id == record.id }) {
            historyRecords[idx] = record
            persistHistory()
        }
    }
    
    private func persistHistory() {
        if let data = try? JSONEncoder().encode(historyRecords) {
            try? data.write(to: historyURL, options: .atomic)
        }
    }
    
    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let loaded = try? JSONDecoder().decode([FaxTransmissionRecord].self, from: data) else {
            return
        }
        self.historyRecords = loaded
    }
    
    // MARK: - Signatures
    public func saveSignature(data: Data) {
        savedSignatures.append(data)
        if let encoded = try? JSONEncoder().encode(savedSignatures) {
            try? encoded.write(to: signaturesURL, options: .atomic)
        }
    }
    
    public func deleteSignature(at index: Int) {
        guard index < savedSignatures.count else { return }
        savedSignatures.remove(at: index)
        if let encoded = try? JSONEncoder().encode(savedSignatures) {
            try? encoded.write(to: signaturesURL, options: .atomic)
        }
    }
    
    private func loadSignatures() {
        guard let data = try? Data(contentsOf: signaturesURL),
              let loaded = try? JSONDecoder().decode([Data].self, from: data) else {
            return
        }
        self.savedSignatures = loaded
    }
    
    // MARK: - Mock Data for Screenshots
    private func populateMockDataIfEmpty() {
        if contacts.isEmpty {
            contacts = [
                FaxRecipient(name: "Acme Healthcare Clinic", organization: "Records Dept", countryCode: "US", dialCode: "+1", faxNumber: "(415) 555-0199", isFavorite: true),
                FaxRecipient(name: "Legal Counsel & Partners", organization: "Contracts Office", countryCode: "US", dialCode: "+1", faxNumber: "(212) 555-0144", isFavorite: true),
                FaxRecipient(name: "Tokyo Finance Bureau", organization: "Audit Div", countryCode: "JP", dialCode: "+81", faxNumber: "3-5555-0188", isFavorite: false)
            ]
            persistContacts()
        }
        
        if historyRecords.isEmpty {
            historyRecords = [
                FaxTransmissionRecord(confirmationCode: "FAX-884920", recipient: FaxRecipient(name: "Apex Medical Center", organization: "Records", countryCode: "US", dialCode: "+1", faxNumber: "(555) 382-9011"), sentDate: Date().addingTimeInterval(-3600), completedDate: Date().addingTimeInterval(-3540), pageCount: 3, status: .delivered, creditsUsed: 3, transmissionDurationSeconds: 48, subject: "Patient Referral & Consent"),
                FaxTransmissionRecord(confirmationCode: "FAX-610294", recipient: FaxRecipient(name: "Global Logistics AG", organization: "Import/Export", countryCode: "DE", dialCode: "+49", faxNumber: "30 8921 4410"), sentDate: Date().addingTimeInterval(-86400 * 2), completedDate: Date().addingTimeInterval(-86400 * 2 + 65), pageCount: 2, status: .delivered, creditsUsed: 2, transmissionDurationSeconds: 65, subject: "Commercial Invoice & Bill of Lading"),
                FaxTransmissionRecord(confirmationCode: "FAX-391827", recipient: FaxRecipient(name: "Standard Insurance Co", organization: "Claims", countryCode: "US", dialCode: "+1", faxNumber: "(800) 555-0182"), sentDate: Date().addingTimeInterval(-86400 * 5), completedDate: Date().addingTimeInterval(-86400 * 5 + 35), pageCount: 1, status: .delivered, creditsUsed: 1, transmissionDurationSeconds: 35, subject: "Proof of Loss Form")
            ]
            persistHistory()
        }
    }
}
